# media_build-libreelec
Compile [media_build](https://www.linuxtv.org/wiki/index.php/How_to_Obtain,_Build_and_Install_V4L-DVB_Device_Drivers) for LibreELEC / Odroid C2 (repack SYSTEM image):

Compile LibreELEC:

	$ git clone https://github.com/anor-es/LibreELEC.tv.7.0.git
	$ cd LibreELEC.tv.7.0
	$ git checkout dvb_drivers
	$ PROJECT=Odroid_C2 ARCH=aarch64 make release
	$ cd ..

Then, compile media_build:

	$ git clone https://github.com/anor-es/media_build-libreelec.git
	$ cd media_build-libreelec
	$ ./compile-media_build.sh

New repack file located in target directory  
After first boot LibreELEC please do (via ssh session):

	$ echo "3.14.65-media_build" > /storage/downloads/dvb-drivers.txt
	$ reboot
