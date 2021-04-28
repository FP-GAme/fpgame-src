# Depmod

This folder contains a bin file created by the depmod command.

Our goal was to automatically load our APU, CON, and PPU kernel modules without
manual user intervention. This works only after depmod is run. However, we
don't want to run depmod manually or at every boot. Instead, running low on
time, we just added the resulting bin file to this folder to be copied by our
build-script.sh.
