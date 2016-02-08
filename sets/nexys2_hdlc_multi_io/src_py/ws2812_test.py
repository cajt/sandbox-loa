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

    set_ws2812(fpga, 10, 0, 0, n=0)
    set_ws2812(fpga, 0, 10, 0, n=1)
    set_ws2812(fpga, 0, 0, 10, n=2)
    set_ws2812(fpga, 10, 10, 0, n=3)
    set_ws2812(fpga, 0, 10, 10, n=4)
    set_ws2812(fpga, 10, 0, 10, n=5)
    set_ws2812(fpga, 0, 0, 10, n=6)
    set_ws2812(fpga, 10, 10, 0, n=7)

    set_ws2812(fpga, 10, 0, 0, n=8)
    set_ws2812(fpga, 0, 10, 0, n=9)
    set_ws2812(fpga, 0, 0, 10, n=10)
    set_ws2812(fpga, 10, 10, 0, n=11)
    set_ws2812(fpga, 0, 10, 10, n=12)
    set_ws2812(fpga, 10, 0, 10, n=13)
    set_ws2812(fpga, 0, 0, 10, n=14)
    set_ws2812(fpga, 10, 10, 0, n=15)

    time.sleep(3)


    for t in range(2):
      for n in range(16):
        set_ws2812(fpga, t*0x20, t*0x20, t*0x20, n=n)
        time.sleep(0.01)

    for t in range(2, -1, -1):
      for n in range(16):
        set_ws2812(fpga, t*0x20, t*0x20, t*0x20, n=n)
        time.sleep(0.01)

    set_ws2812(fpga, 10, 0, 0, n=0)
    set_ws2812(fpga, 0, 10, 0, n=1)
    set_ws2812(fpga, 0, 0, 10, n=2)
    set_ws2812(fpga, 10, 10, 0, n=3)
    set_ws2812(fpga, 0, 10, 10, n=4)
    set_ws2812(fpga, 10, 0, 10, n=5)
    set_ws2812(fpga, 0, 0, 10, n=6)
    set_ws2812(fpga, 10, 10, 0, n=7)

    set_ws2812(fpga, 10, 0, 0, n=8)
    set_ws2812(fpga, 0, 10, 0, n=9)
    set_ws2812(fpga, 0, 0, 10, n=10)
    set_ws2812(fpga, 10, 10, 0, n=11)
    set_ws2812(fpga, 0, 10, 10, n=12)
    set_ws2812(fpga, 10, 0, 10, n=13)
    set_ws2812(fpga, 0, 0, 10, n=14)
    set_ws2812(fpga, 10, 10, 0, n=15)


