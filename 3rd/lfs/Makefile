  
.PHONY : all linux

all : linux

linux :
	gcc -g -Wall -fPIC --shared -o lfs.so lfs.c

macosx :
	gcc -g -Wall --shared -undefined dynamic_lookup -o lfs.so lfs.c

clean :
	rm -rf lfs.so