linux:
	cd 3rd/skynet;make clean;make linux
	cd 3rd/lfs;make clean;make linux
macosx:
	cd 3rd/skynet;make clean;make macosx
	cd 3rd/lfs;make clean;make macosx

clean :
	cd 3rd/skynet;make clean
	cd 3rd/lfs;make clean

