#!/usr/bin/env python 
import math
      
class DDS:
  def __init__(self, fpga, addr, basefreq=50e6):
    self.fpga=fpga
    self.addr=addr
    self.basefreq=basefreq

  def set_freq(self, f):
    p = int (f / (self.basefreq/(2**32)))
    self.fpga.write(self.addr + 0x401, p & 0xffff)
    self.fpga.write(self.addr + 0x402, (p >> 16) & 0xffff)
    self.fpga.write(self.addr + 0x400, 0x0002) # load
    self.fpga.write(self.addr + 0x400, 0x0001) # enable
    return p * self.basefreq/2**32
  
  def load_sine(self):
    for n in range(1024):
	self.fpga.write(self.addr+n, int(math.sin((n/1024.0)*2*math.pi)*0x7fff+0x7fff))
    

if __name__ == "__main__":
  import time
  import sys 
  import hdlc_busmaster

  if len(sys.argv) == 1:
        port = "/dev/ttyUSB0"
  else:
        port = sys.argv[1]

  fpga = hdlc_busmaster.hdlc_busmaster(port)
  dds = DDS(fpga, 0x400)
  dds.load_sine()

  if len(sys.argv) == 3:
    print("actual value: %f" % dds.set_freq(float(sys.argv[2]) ) )
  else:
    print("actual value: %f" % dds.set_freq(440) )

  
