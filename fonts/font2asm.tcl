if {$argc < 1} {
	puts "Usage tclsh $argv0 <fontfile>"
	exit
}

proc decodeBmp {b} {
	set ret 0
	foreach c $b {
		scan $c %x a
		set ret [expr ($ret << 6) | ($a >> 2)]
	}
	return $ret
}

proc fixName {n} {
	switch -regexp $n {
		^[a-z]{1}$	{ return "low_$n" }
		^[A-Z]{1}$	{ return "cap_$n" }
		^at$        { return "sym_at" }
		default     { return $n }
	}
}

set allTxt [read [open [lindex $argv 0]]]
set lines [split $allTxt "\n"]

foreach l $lines {
	if {$l eq ""} continue

	set name [lindex $l 0]
	set code [lindex $l 1]
	set bmp  [lrange $l 2 end]
	puts ".[fixName $name]: ; $code\n\tdq 0x[format %lx [decodeBmp $bmp]]"
}

