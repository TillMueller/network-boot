# File Injection for Virtual Machine Boot Mechanisms

This project aims to enable the modification of a file system attached to the machine before booting the actual kernel either from disk or a network location.

### Features:
- Add files to any place on any filesystem connected to the machine
- Connect to the machine via SSH during this phase to make manual changes or debug boot issues
- Freely choose which kernel / initramfs / cmdline should be used for the final boot

### How to use this project
1. Get an initramfs image from Debian 10 Buster (can be found in the /boot directory)

2. Extract the image into a folder
	```
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

5. On the HTTP server, clone the ```network-boot-http``` repository so that http://{YOUR SERVER IP}/config.sh accesses the ```config.sh``` file.

6. Boot using the newly create initrd and the latest Debian Buster Kernel (tested with ```4.19.0-5-amd64```) via KVM direct kernel boot or PXE. For the system to work the kernel boot parameters have to contain a ```server={IP OF YOUR HTTP SERVER}``` setting.

7. The machine will now try to establish a network connection using DHCP. After that, the current IP configuration of the machine will be displayed on screen, should you wish to connect to the machine via SSH to test / debug or do further manual configuration before booting the final kernel. To make this easier, the machine waits for five seconds after establishing a network connection and will not continue booting, as long as an SSH connection is established. If you want to make the system stop trying to boot completely, do ```echo 1 > /network-boot/cancel_boot```, this will cause the start-up script to exit.

8. The ```config.sh``` script can mount and load arbitray filesystems and files, an example is given in ```network-boot-http/add_files.sh```
9. The boot of the "real" kernel is done using kexec. For examples for booting either from a local disk or a network location (by first downloading and then loading the kernel), see ```network-boot-http/hdd_kernel.sh``` and ```network-boot-http/network_kernel.sh```
