cmd_/home/andy/Documents/Projects/Capstone/Kernel/modules.order := {   echo /home/andy/Documents/Projects/Capstone/Kernel/con/con.ko;   echo /home/andy/Documents/Projects/Capstone/Kernel/apu/apu.ko; :; } | awk '!x[$$0]++' - > /home/andy/Documents/Projects/Capstone/Kernel/modules.order
