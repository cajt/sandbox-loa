#!/usr/bin/env python 

import time
import sys 
import hdlc_busmaster
      

def set_ws2812(fpga, r,g,b,n=0, base=0x1000):
    fpga.write(base + 2 * n, b + r * 256)
    fpga.write(base + 2 * n +1, g)
    

if __name__ == "__main__":
    if len(sys.argv) == 1:
        port = "/dev/ttyUSB0"
    else:
        port = sys.argv[1]

    fpga = hdlc_busmaster.hdlc_busmaster(port)

    sw = fpga.read(0x0000)
    print sw

    for n in range(16):
      set_ws2812(fpga, 0xff, 0xbf, 0x8f, n=n)

#    time.sleep(5)
#    for n in range(16):
#      set_ws2812(fpga, 0x00, 0x00, 0x00, n=n)



