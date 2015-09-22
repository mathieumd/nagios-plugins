<?php
# PNP4Nagios template for check_snmp_mem.pl
# https://github.com/shinken-monitoring/pack-linux-snmp/blob/master/libexec/check_snmp_mem.pl

$_TOTAL1   = '#ffffff';
$_TOTAL2   = '#444444';
$_FREE     = '#54eb48';
$_CACHED   = '#48c3eb';
$_BUFFERED = '#af8fff';

$opt[1] = "--vertical-label 'Bytes' --base 1024 -l 0 --title 'Memory Usage on $hostname'";

$def[1] = '';

$def[1] .= rrd::def('free', $RRDFILE[1], $DS[1], 'AVERAGE');
$def[1] .= rrd::def('total', $RRDFILE[1], $DS[2], 'AVERAGE');
$def[1] .= rrd::def('cached', $RRDFILE[1], $DS[3], 'AVERAGE');
$def[1] .= rrd::def('buffered', $RRDFILE[1], $DS[4], 'AVERAGE');

$def[1] .= rrd::cdef('free_b', 'free,1024,*');
$def[1] .= rrd::cdef('total_b', 'total,1024,*');
$def[1] .= rrd::cdef('cached_b', 'cached,1024,*');
$def[1] .= rrd::cdef('buffered_b', 'buffered,1024,*');

$def[1] .= rrd::gradient('total_b', $_TOTAL1, $_TOTAL2);

$def[1] .= rrd::area('free_b', $_FREE, rrd::cut('Free'));
$def[1] .= rrd::gprint('free_b', array('LAST', 'AVERAGE', 'MAX'), '%6.1lf%s');

$def[1] .= rrd::area('cached_b', $_CACHED, rrd::cut('Cache'), 'STACK');
$def[1] .= rrd::gprint('cached_b', array('LAST', 'AVERAGE', 'MAX'), '%6.1lf%s');

$def[1] .= rrd::area('buffered_b', $_BUFFERED, rrd::cut('Buffers'), 'STACK');
$def[1] .= rrd::gprint('buffered_b', array('LAST', 'AVERAGE', 'MAX'), '%6.1lf%s');

?>
