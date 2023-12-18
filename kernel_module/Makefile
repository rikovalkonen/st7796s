obj-m := fb_st7796s.o

PWD := $(shell pwd)

EXTRA_CFLAGS += -Wno-incompatible-pointer-types

all: default

default:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

install:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules_install

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean