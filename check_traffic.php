<?php
$_WARNRULE = '#FFFF00';
$_CRITRULE = '#FF0000';
# Array with different colors by trio: Line, Gradient1, Gradient2
$colors = array(
        'FFDDBF', 'FFBB7F', 'FF7700',
        'D7BFFF', 'B07FFF', '6100FF',
        );
# Counter used to pick the color by trio
$color=0;

$fmt='%3.2lf';

$interface=0;

foreach ($this->DS as $KEY=>$VAL) {
    # Colors choice loop
    if ($color == count($colors)) { $color = 0; }
    $negative=false;
    if (preg_match('/^([-:a-zA-Z0-9]+)-([rt]x)$/', $VAL['NAME'], $name)) {
        $title = $name[1];
        $label = $name[2];
    }
    if ($label == 'rx') {
        ++$interface;
        $vlabel = $VAL['UNIT'];
        $opt[$interface] = '--vertical-label "' . $vlabel . '" --title "' . $this->MACRO['DISP_HOSTNAME'] . ' / ' . $title . ' ' . $this->MACRO['DISP_SERVICEDESC'] . '"';
        $def[$interface] = '';
        $negative=true;
    }
    $ds_name[$interface] = $title;

    $def[$interface] .= rrd::def     ("var$KEY", $VAL['RRDFILE'], $VAL['DS'], "AVERAGE");
    if ($negative) {
        $def[$interface] .= rrd::cdef    ("var{$KEY}_neg", "var$KEY,-1,*");
        $def[$interface] .= rrd::gradient("var{$KEY}_neg", "#".$colors[$color++], "#".$colors[$color++], '', 20);
        $def[$interface] .= rrd::line1   ("var{$KEY}_neg", "#".$colors[$color++], rrd::cut($label, 4));
    } else {
        $def[$interface] .= rrd::gradient("var$KEY", "#".$colors[$color++], "#".$colors[$color++], '', 20);
        $def[$interface] .= rrd::line1   ("var$KEY", "#".$colors[$color++], rrd::cut($label, 4));
    }
    $def[$interface] .= rrd::gprint  ("var$KEY", array("LAST","MAX","AVERAGE"), $fmt." %S".$VAL['UNIT']);

    if ($label == 'tx') {
        $max = '';
        if ($VAL['MAX'] != '') { $max = pnp::adjust_unit($VAL['MAX'],1000,'%3.0lf'); }
        if ($max != '') {
            $def[$interface] .= rrd::comment("Max\: $max[0]$vlabel\\r");
        }
    }
}
?>
