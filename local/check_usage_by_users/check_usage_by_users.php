<?php
$_WARNRULE = '#FFFF00';
$_CRITRULE = '#FF0000';
# Array with different colors by trio: Line, Gradient1, Gradient2
$colors = array(
        'BFFFE9', '7FFFD4', '00FFA9',
        'FFBFFA', 'FF7FF6', 'FF00EE',
        'FFECBF', 'FFDA7F', 'FFB600',
        'FFDDBF', 'FFBB7F', 'FF7700',
        'D4FFBF', 'AAFF7F', '54FF00',
        'D7BFFF', 'B07FFF', '6100FF',
        );
# Counter used to pick the color by trio
$color=0;

$fmt='%3.2lf';

$def[1]='';

foreach ($this->DS as $KEY=>$VAL) {
    # Colors choice loop
    if ($color == count($colors)) { $color = 0; }
    $vlabel   = " ";
    $warning  = "";
    $critical = "";
    if ($VAL['UNIT'] == "%%") {
        $vlabel = "%";
    } else {
        $vlabel = $VAL['UNIT'];
    }
    if ($VAL['WARN'] != "") {
        $warning = $VAL['WARN'];
    }
    if ($VAL['CRIT'] != "") {
        $critical = $VAL['CRIT'];
    }
    $def[1] .= rrd::def     ("var$KEY", $VAL['RRDFILE'], $VAL['DS'], "AVERAGE");
    $def[1] .= rrd::gradient("var$KEY", "#".$colors[$color++], "#".$colors[$color++], '', 20);
    $def[1] .= rrd::line1   ("var$KEY", "#".$colors[$color++], rrd::cut($VAL['NAME'], 16));
    $def[1] .= rrd::gprint  ("var$KEY", array("LAST","MAX","AVERAGE"), $fmt." %S".$VAL['UNIT']);
}

if ($warning != "" && $critical != "") {
    $def[1] .= rrd::hrule($warning, $_WARNRULE, "Warning\: $warning ");
    $def[1] .= rrd::hrule($critical, $_CRITRULE, "Critical\: $critical \\r");
}

$opt[1] = '--vertical-label "' . $vlabel . '" --title "' . $this->MACRO['DISP_HOSTNAME'] . ' / ' . $this->MACRO['DISP_SERVICEDESC'] . '"';

?>
