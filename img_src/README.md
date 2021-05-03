# img_src
This folder marks the directory to copy the de10_nano_linux_console.img file
during the build from source process.

Also, this directory contains some additional files we copy during the auto-build process:
* systemd/fpgame.service
* systemd/fpgame.sh
* depmod/modules.depmod.bin

The full build_from_source_guide.pdf can be found in this repository under the docs subdirectory.

Reminders:
* The de10_nano_linux_console.img file can be downloaded from the following link:
https://www.terasic.com.tw/cgi-bin/page/archive.pl?No=1046&PartNo=4
* This de10_nano_linux_console.img file must be copied/moved to this folder before running the build-script.
