#!/usr/bin/env python 

import time
import sys 
import hdlc_busmaster
      

if __name__ == "__main__":
    if len(sys.argv) == 1:
        port = "/dev/ttyUSB0"
    else:
        port = sys.argv[1]

    fpga = hdlc_busmaster.hdlc_busmaster(port)

    sw = fpga.read(0x0000)
    print sw

    for n in range(10):
	fpga.write(0x0000, 0x5555)
	time.sleep(0.25)
        fpga.write(0x0000, 0xAAAA)
	time.sleep(0.25)

