<?php
# PNP4Nagios template for:
# check_snmp_load.pl

$_COLORWARN = '#FFFF00';
$_COLORCRIT = '#FF0000';

$_COLOR[] = '#FFA858'; # OK
$_COLOR[] = '#C05800'; # Warn
$_COLOR[] = '#C00000'; # Crit
$_COLOR[] = '#000000'; # Line
$_COLOR[] = '#FFFFFF'; # Start

$opt[1] = "--vertical-label '%' --title 'CPU Load for $hostname'";

$def[1] = '';

$def[1] .= rrd::def('cpu_used', $RRDFILE[1], $DS[1], 'AVERAGE');

if($WARN[1] != "" && $CRIT[1] != ""){
    $def[1] .= rrd::alerter_gr('cpu_used', rrd::cut('CPU Load'), $WARN[1], $CRIT[1], "FF", $UNIT[1], $_COLOR[0], $_COLOR[1], $_COLOR[2], $_COLOR[3], $_COLOR[4]);
} else {
    $def[1] .= rrd::gradient('cpu_used', $_COLOR[0], $_COLOR[2], rrd::cut('CPU Load'));
}
$def[1] .= rrd::gprint('cpu_used', array('LAST', 'AVERAGE', 'MAX'), '%6.2lf%s');

if($WARN[1] != ""){
    if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
    $def[1] .= rrd::hrule($WARN[1], $_COLORWARN, "Warning   ".$WARN[1].$UNIT[1]."\\n");
}
if($CRIT[1] != ""){
    if($UNIT[1] == "%%"){ $UNIT[1] = "%"; };
    $def[1] .= rrd::hrule($CRIT[1], $_COLORCRIT, "Critical  ".$CRIT[1].$UNIT[1]."\\n");
}

?>
