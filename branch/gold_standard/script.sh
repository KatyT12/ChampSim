#!/opt/tools/bsc/latest/bin/bluetcl
package require Bluesim
#Bluesim::sim load mkTestbench_bsim.so mkTestbench
# ./mkTestbench_bsim.so -f script.sh

#parray env
#set infd [lindex $argv 0]
#set outfd [lindex $argv 1]


Bluesim::sim load branch/gold_standard/Build/mkTestbench_bsim.so mkTestbench
#Bluesim::sim arg "DEBUG"


#Bluesim::sim arg "OUT=$outfd"

#puts [Bluesim::sim ls]
#set output [Bluesim::sim ls]
#puts $output
Bluesim::sim run