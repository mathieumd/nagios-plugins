<?php
# PNP4Nagios template for:
# check_fortigate.pl -T mem

$_COLORWARN = '#FFFF00';
$_COLORCRIT = '#FF0000';

$_COLOR[] = '#0000A0'; # Start
$_COLOR[] = '#0000FF'; # End

$opt[1] = "--vertical-label '%' -l 0 --upper-limit 100 --title 'Memory Usage on $hostname'";

$def[1] = '';
$def[1] .= rrd::def('used', $RRDFILE[1], $DS[1], 'AVERAGE');
$def[1] .= rrd::gradient('used', $_COLOR[0], $_COLOR[1], rrd::cut('Used memory'));
$def[1] .= rrd::gprint('used', array('LAST', 'AVERAGE', 'MAX'), '%6.1lf%s');

if($WARN[1] != ""){
    if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
    $def[1] .= rrd::hrule($WARN[1], $_COLORWARN, "Warning   ".$WARN[1].$UNIT[1]."\\n");
}
if($CRIT[1] != ""){
    if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
    $def[1] .= rrd::hrule($CRIT[1], $_COLORCRIT, "Critical  ".$CRIT[1].$UNIT[1]."\\n");
}

?>
