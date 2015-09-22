<?php
#
# This is a template for the visualisation addon PNP (http://www.pnp4nagios.org)
#
# Plugin: check_nwc_health - https://labs.consol.de/nagios/check_nwc_health/
# Release 1.2 (2015-09-21)
#
# Supported modes:
# - interface-usage
# - interface-errors
#
# Note: Interfaces names may have several formats:
# - eth0_usage_in / _out
# - eth0_0_usage_in / _out
# - GigabitEthernet 0/0_usage_in / _out
#

$_WARNRULE = '#FFFF00';
$_CRITRULE = '#FF0000';

$_USAGEIN  = '#000066';
$_USAGEOUT = '#0000FF';

$_TRAFFICIN  = $_USAGEIN;
$_TRAFFICOUT = $_USAGEOUT;

$_ERRORSIN  = '#660000';
$_ERRORSOUT = '#CC0000';

$def[1] = "";
$opt[1] = "";

$num = 1;
foreach ($DS as $i=>$VAL) {

    ########################################################
    # --mode interface-usage
    ########################################################

    # Usage
    if(preg_match('/^(.*?)_usage_in/', $NAME[$i])) {
        $interface = preg_replace('/_usage_.*$/', '', $LABEL[$i]);
        $ds_name[$num] = $interface.' usage';
        $opt[$num]  = "--vertical-label \"Usage\" -l 0 -u 100 --title \"Interface Usage for $hostname - ".$interface."\" ";
        $def[$num]  = "DEF:percin=$RRDFILE[$i]:$DS[$i]:AVERAGE ";
        $def[$num] .= "DEF:percout=".$RRDFILE[$i+1].":".$DS[$i+1].":AVERAGE ";
        $def[$num] .= "LINE2:percin$_USAGEIN:\"in\t\" ";
        $def[$num] .= "GPRINT:percin:LAST:\"%10.1lf %% last\" ";
        $def[$num] .= "GPRINT:percin:AVERAGE:\"%7.1lf %% avg\" ";
        $def[$num] .= "GPRINT:percin:MAX:\"%7.1lf %% max\\n\" ";
        $def[$num] .= "LINE2:percout$_USAGEOUT:\"out\t\" ";
        $def[$num] .= "GPRINT:percout:LAST:\"%10.1lf %% last\" ";
        $def[$num] .= "GPRINT:percout:AVERAGE:\"%7.1lf %% avg\" ";
        $def[$num] .= "GPRINT:percout:MAX:\"%7.1lf %% max\"\\n ";
        $def[$num] .= rrd::hrule($WARN[$i], $_WARNRULE);
        $def[$num] .= rrd::hrule($CRIT[$i], $_CRITRULE);
        $num++;
    }

    # Traffic
    if(preg_match('/^(.*?)_traffic_in/', $NAME[$i])) {
        $interface = preg_replace('/_traffic_.*$/', '', $LABEL[$i]);
        $ds_name[$num] = $interface.' traffic';
        $opt[$num]  = "--vertical-label \"Traffic\" -b 1024 --title \"Interface Traffic for $hostname - $interface\" ";
        $def[$num]  = "DEF:bitsin=$RRDFILE[$i]:$DS[$i]:AVERAGE ";
        $def[$num] .= "DEF:bitsout=".$RRDFILE[$i+1].":".$DS[$i+1].":AVERAGE ";
        $def[$num] .= "AREA:bitsin$_TRAFFICIN:\"in\t\" ";
        $def[$num] .= "GPRINT:bitsin:LAST:\"%10.1lf %Sb/s last\" ";
        $def[$num] .= "GPRINT:bitsin:AVERAGE:\"%7.1lf %Sb/s avg\" ";
        $def[$num] .= "GPRINT:bitsin:MAX:\"%7.1lf %Sb/s max\\n\" ";
        $def[$num] .= "CDEF:bitsminusout=0,bitsout,- ";
        $def[$num] .= "AREA:bitsminusout$_TRAFFICOUT:\"out\t\" ";
        $def[$num] .= "GPRINT:bitsout:LAST:\"%10.1lf %Sb/s last\" ";
        $def[$num] .= "GPRINT:bitsout:AVERAGE:\"%7.1lf %Sb/s avg\" ";
        $def[$num] .= "GPRINT:bitsout:MAX:\"%7.1lf %Sb/s max\\n\" ";
        $num++;
    }


    ########################################################
    # --mode interface-errors
    ########################################################

    if(preg_match('/^(.*?)_errors_in/', $NAME[$i])) {
        $interface = preg_replace('/_errors_.*$/', '', $LABEL[$i]);
        $ds_name[$num] = $interface.' errors';
        $opt[$num]  = "--vertical-label \"Errors/sec\" -b 1024 --title \"Interface Errors for $hostname - $interface\" ";
        $def[$num]  = "DEF:errin=$RRDFILE[$i]:$DS[$i]:AVERAGE ";
        $def[$num] .= "DEF:errout=".$RRDFILE[$i+1].":".$DS[$i+1].":AVERAGE ";
        $def[$num] .= "AREA:errin$_ERRORSIN:\"in\t\" ";
        $def[$num] .= "GPRINT:errin:LAST:\"%10.1lf %Se/s last\" ";
        $def[$num] .= "GPRINT:errin:AVERAGE:\"%7.1lf %Se/s avg\" ";
        $def[$num] .= "GPRINT:errin:MAX:\"%7.1lf %Se/s max\\n\" ";
        $def[$num] .= "CDEF:errminusout=0,errout,- ";
        $def[$num] .= "AREA:errminusout$_ERRORSOUT:\"out\t\" ";
        $def[$num] .= "GPRINT:errout:LAST:\"%10.1lf %Se/s last\" ";
        $def[$num] .= "GPRINT:errout:AVERAGE:\"%7.1lf %Se/s avg\" ";
        $def[$num] .= "GPRINT:errout:MAX:\"%7.1lf %Se/s max\\n\" ";
        $num++;
    }

}
?>
