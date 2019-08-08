# File Injection for Virtual Machine Boot Mechanisms

This project aims to enable the modification of a file system attached to the machine before booting the actual kernel either from disk or a network location.

### Features:
- Add files to any place on any filesystem connected to the machine
- Connect to the machine via SSH during this phase to make manual changes or debug boot issues
- Freely choose which kernel / initramfs / cmdline should be used for the final boot

### How to use this project
1. Get an initramfs image from Debian 10 Buster (can be found in the ```/boot``` directory of most machines running Debian)

2. Extract the image into a folder
	```
	git clone https://{SERVER}/network-boot.git
	mkdir initrd
	cd initrd
	zcat ../{YOUR INITRD FILE} | cpio -i -H newc -d
	```

3. Copy all files from this repository into the newly created folder
	```
	cp -r ../network-boot/* .
	```

4. Package the folder into a new initrd file
	```
	find | cpio -o -H newc | gzip -4 > ../{NAME OF THE PATCHED INITRD ARCHIVE}
	```

5. On the HTTP server, clone the ```network-boot-http``` repository so that ```http://{YOUR SERVER IP}/config.sh``` accesses the ```config.sh``` file. It is important that this file exists and is called ```config.sh``` since the start-up script will try to load and execute exactly this file. Additionally, the system will try to get an ```index.html``` from the HTTP server. This file is downloaded and then displayed during the inital boot process.

6. Boot using the newly create initrd and the latest Debian Buster Kernel (tested with ```4.19.0-5-amd64```) via KVM direct kernel boot or PXE. For the system to work the kernel boot parameters have to contain a ```server={IP OF YOUR HTTP SERVER}``` setting.

7. The machine will now try to establish a network connection using DHCP. After that, the current IP configuration of the machine will be displayed on screen, should you wish to connect to the machine via SSH to test / debug or do further manual configuration before booting the final kernel. To make this easier, the machine waits for five seconds after establishing a network connection and will not continue booting, as long as an SSH connection is established. If you want to make the system stop trying to boot completely, do ```echo 1 > /network-boot/cancel_boot```, this will cause the start-up script to exit.

8. The ```config.sh``` script can mount and load arbitray filesystems and files, an example is given in ```network-boot-http/add_files.sh```
9. The boot of the "real" kernel is done using kexec. For examples for booting either from a local disk or a network location (by first downloading and then loading the kernel), see ```network-boot-http/hdd_kernel.sh``` and ```network-boot-http/network_kernel.sh```

### Using the scripts that came packaged with ```network-boot-http```

```config.sh``` contains almost all parameters used during the boot process, including which kernel to boot, where to get it from which server to load subsequent files from (can be different from the server serving ```config.sh``` itself and the parameters to be passed to the final kernel. 
The parameters are (including default values):
	- ```BOOT_MODE="NETWORK"``` - whether to use the ```network_kernel.sh``` or ```hdd_kernel.sh``` script. For the latter use ```BOOT_MODE="HDD"```
	- ```KERNEL="vmlinuz-4.19.0-5-amd64"``` - the name of the kernel file.
		If using the ```NETWORK``` boot mode, this file has to be placed on the server set by ```SERVER``` in a subfolder called ```kernels```, so that ```http://{$SERVER}/kernels/$kernel``` points to it.
		If using the ```HDD``` boot mode, ```KERNEL``` has to be set to the full path of the kernel file within the filesystem given in ```HDD```, e.g. ```KERNEL="/boot/vmlinuz-4.9.0-9-amd64"```
	- ```INITRD="initrd.img-4.19.0-5-amd64"```` - Name of the initrd file.
		Similar to the ```KERNEL``` paramter, this file can be in a network location (also in the ```kernels``` folder) or in the mounted filesystem, e.g. ```INITRD="/boot/initrd.img-4.9.0-9-amd64"```
	- ```SERVER="192.168.123.216"``` - Which server to load all subsequent files from. This value may not contain spaces
	- ```HDD="/dev/vda1"``` - Which device contains the filesystem that files should be added to using ```add_files.sh``` and if ```BOOT_MODE="HDD"``` is set, which device contains the kernel and initrd to load later
	- ```FILESYSTEM="ext4"``` - What filesystem the device set with ```HDD``` contains. This is directly passed to ```mount```
	- ```CMDLINE="root=$HDD ro quiet panic=1"``` - What arguments to pass to the final kernel when booting it. ```panic=1``` is advised here as otherwise a boot failure will probably cause the new kernel to switch to it's own initramfs console which will be unavailable via SSH. ```panic=1``` causes most Linux kernels to reboot if a boot failure occurs, making it possible to connect to the machine via SSH before the final kernel is booted and debug the issue.

