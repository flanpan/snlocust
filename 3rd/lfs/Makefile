  
.PHONY : all linux

all : linux

linux :
	gcc -g -Wall -std=gnu99 -fPIC --shared -o lfs.so lfs.c -I../skynet/3rd/lua

macosx :
	gcc -g -Wall --shared -undefined dynamic_lookup -o lfs.so lfs.c

clean :
	rm -rf lfs.so