# File Injection for Virtual Machine Boot Mechanisms

This project aims to enable the modification of a file system attached to the machine before booting the actual kernel either from disk or a network location.

### Features
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
5. Get the source for the linux kernel ```apt install linux-source-4.19```, extract it ```tar xf /usr/src/linux-source-4.19.tar.xz``` and switch into the directory ```cd linux-source-4.19```
6. Create config by running ```make localyesconfig``` and answering all questions with "no". Now disable signature checking by running ```scripts/config --disable MODULE_SIG```. A config created using a qemu debian virtual machine can be found under ```.config``` included in this repository
7. Copy the patched INITRD archive from above into the folder as ```initramfs_data.cpio.gz```
8. Edit the ```.config``` file on line 161 to add the initramfs archive from above to the kernel: ```CONFIG_INITRAMFS_SOURCE="initramfs_data.cpio.gz"```
9. Compile the kernel by running ```make -j $(nproc) bzImage``` answering all questions with the default answer by pressing return. The kernel will appear in ```arch/x86/boot/bzImage``` and can now be used to boot virtual machines using KVM direct kernel boot.

### Using the kernel to inject files into the machine's filesystem
10. When booting the machine using the kernel created above, also include an initramfs that includes a folder called ```fs_overlay```. All files and folders in there will be copied to the booting machine's filesystem (e.g. fs_overlay/etc/motd will be copied to /etc/motd)

### The following steps are only necessary when using the HTTP boot option by setting the ```server``` variable in the kernel boot arguments
11. On the HTTP server, clone the ```network-boot-http``` repository so that ```http://{YOUR SERVER IP}/config.sh``` accesses the ```config.sh``` file. It is important that this file exists and is called ```config.sh``` since the start-up script will try to load and execute it. Additionally, the system will try to get an ```index.html``` from the HTTP server. This file is downloaded and then displayed during the inital boot process using ```cat```. If ```index.html``` does not exist, ```wget``` will display an error during boot, which can be ignored.
12. Boot using the newly created initrd and the latest Debian Buster Kernel (tested with ```vmlinuz-4.19.0-5-amd64```) via KVM direct kernel boot or PXE. For the system to work the kernel boot parameters have to contain a ```server={IP OF YOUR HTTP SERVER}``` setting.
13. The machine will now try to establish a network connection using DHCP. After that, the current IP configuration of the machine will be displayed on screen, should you wish to connect to the machine via SSH to test / debug or do further manual configuration before booting the final kernel. To make this easier, the machine waits for five seconds after establishing a network connection and will not continue booting as long as an SSH connection is established. If you want to make the system stop trying to boot completely, do ```echo 1 > /network-boot/cancel_boot```, this will cause the start-up script to exit.
14. The ```config.sh``` script can mount and load arbitrary filesystems and files, an example is given in ```network-boot-http/add_files.sh```
15. The boot of the "real" kernel is done using kexec. For examples for booting either from a local disk or a network location (by first downloading and then loading the kernel), see ```network-boot-http/hdd_kernel.sh``` and ```network-boot-http/network_kernel.sh```

### Additional files
The ```network-boot-http``` repo contains additional files that deliver all required functionality needed for a successful boot using this system with only some configuration required. This is the best way to get up and running quickly.