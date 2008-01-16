<?php 

# This file just forwards any requests made to a subdirectory to http://localhost:3000/ -- and replaces any outgoing strings' links with the right url so that a rails app can live in a subdirectory peacefully.
# note that it is slower than fcgi and cgi right now as it doesn't allow users to cache anything yet.  But with time...
# Note it doesn't work with cookies or redirects yet.
# Enjoy.
# Freeware/open source/use and abuse.
# -Roger

if(file_exists($DOCUMENT_ROOT.$REQUEST_URI)
and ($SCRIPT_FILENAME!=$DOCUMENT_ROOT.$REQUEST_URI)
and ($REQUEST_URI!="/")){
  $url=$REQUEST_URI;
  include($DOCUMENT_ROOT.$url);
  exit();
}

$last_slash = strrpos($_SERVER['SCRIPT_NAME'], '/'); # the subdir badness--if the apache .htaccess takes this off, then..might break?  Maybe not.
$strip_this_prefix_yes_ending_slash = substr($_SERVER['SCRIPT_NAME'], 1, $last_slash);
$flattened_uri = substr($_SERVER["REQUEST_URI"], $last_slash); # grab just the end of it
$url = 'http://localhost:3000' . $flattened_uri;
#echo 'actually requesting' . $url. '<br>';
$curl_handler = curl_init(); // init the cURL session.
curl_setopt($curl_handler, CURLOPT_RETURNTRANSFER, 1); // return as a string to us instead of printing it out
curl_setopt($curl_handler, CURLOPT_BINARYTRANSFER, 1);
curl_setopt($curl_handler, CURLOPT_URL, $url); // send the URL as a parameter.
$result = curl_exec($curl_handler); // transmit the URL to a variable.
function replace_within_result($str, $replacement)
{
  global $result; # only way to have scope
  $result = preg_replace('/' . str_replace('/', '\/', $str) . '/i', $replacement, $result);
}
function post_pend_with_prefix($str)
{
  global $result; global $strip_this_prefix_yes_ending_slash;
  $result = preg_replace('/(' . str_replace('/', '\/', $str) . ')/i', "$1$strip_this_prefix_yes_ending_slash", $result);
}
function sendStatusCode($statusCode)
{
    header(' ', true, $statusCode); # apparently a necessary phph hack
}
# ltodo so it seems that we don't have the liberty of 
$string = 'April 15 2003';
$pattern = '/((\w+) (\d+) (\d+))/i';
$replacement = '${1}, ${2}, ${3}';

$type = curl_getinfo($curl_handler, CURLINFO_CONTENT_TYPE);
// Get response code
$response_code = curl_getinfo($curl_handler, CURLINFO_HTTP_CODE);
curl_close($curl_handler); // close the cURL session and save the system resource

// Not found?
if ($response_code == '404') {
        sendStatusCode(404);
} else {
  header('Content-Type: ' . $type);
  # some of them have Content-Type: application/octet-stream--and err if we just say everything is html
  # kill the easy strings
  #$result = "http://wbo/new_prefi == http://localhost:3000/new_prefix<br> src='/abc' == src=' /ties/abc'" . $result;
  replace_within_result('http://localhost:3000/', 'http://' . $_SERVER["HTTP_HOST"] . '/' . $strip_this_prefix_yes_ending_slash);

# COMMENT THESE OUT IF YOU DON'T WANT IT TO DO ANY STRING SUBSTITUTION ON ITS WAY OUT
  post_pend_with_prefix('(src|img|href|script)=(\'|")?/');
  post_pend_with_prefix('url\(/'); # ugh, to accomodate for javascript itself with poor references -- this one could be for statics (?)
#  post_pend_with_prefix('= "/'); # more javascript. ugly
# these tend to take about .1 on a file of size 4K...A
# ltodo optimization of 'this host on that file just include it and be done

# -- todo should check if filename right after it exists, in public, then if yes replace, or maybe for each in public, search, replace (optionally)
}
echo $result;

#$_COOKIE is a hash of all cookie values--I guess we should pass these to curl

#the question is kinda...umm...should we set 'outgoing' cookies a la php's 'setcookie' method, or will they get passed out?
# so I'd guess that we can just get it binary, pass it out.
# ltodo research this pass it in via 'raw' sockets, and thence be able to use the 'real' name instead of replacing here (though we'd still need to add in for hard coded links...hmm...)
#phpinfo();
?>
