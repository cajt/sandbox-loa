
#!/usr/bin/env python 

class spw(object):
    def __init__(self, fpga, baseaddr):
        self.fpga = fpga
        self.baseaddr = baseaddr

    def sendEOP(self):
        fpga.write(self.baseaddr, 0x100 | 0x00)

    def sendEEP(self):
        fpga.write(self.baseaddr, 0x100 | 0x01)

    def send(self, s):
        fpga.write(self.baseaddr, ord(s) & 0xff)

    def read(self):
        fpga.read(self.baseaddr)
    
    def setControl(self, txClkDiv=4, linkStart=True, linkDis=False, autostart=True ):
        val = (int(txClkDiv)<<8) & 0xff00 
        if linkStart: 
            val += 0x2
        if linkDis: 
            val += 0x4
        if autostart: 
            val+= 0x1
        fpga.write(self.baseaddr+2, val)

    def getStatus(self):
        return fpga.read(self.baseaddr+1)


if __name__ == "__main__":
    import time
    import sys 
    import hdlc_busmaster

    if len(sys.argv) == 1:
        port = "/dev/ttyUSB0"
    else:
        port = sys.argv[1]
    fpga = hdlc_busmaster.hdlc_busmaster(port)
    #sw = fpga.read(0x0000)
    #print hex(sw)

    spw0 = spw(fpga, 0x0010)
    spw1 = spw(fpga, 0x0020)

    print("Actual State")
    #print("SpW Link 0 status: 0x%4.0x" % spw0.getStatus())
    #print("SpW Link 1 status: 0x%4.0x" % spw1.getStatus())

    spw0.setControl(linkStart=False, linkDis=True, autostart=False)
    spw1.setControl(linkStart=False, linkDis=True, autostart=False)

    spw1.send("A")
    spw1.sendEOP()
    print spw0.read()

    print("Link was disabled")
    #print("SpW Link 0 status: 0x%4.0x" % spw0.getStatus())
    #print("SpW Link 1 status: 0x%4.0x" % spw1.getStatus())

    print "gogogo"
    spw0.setControl()
    spw1.setControl()

    print("Link was enabled")
    print("SpW Link 0 status: 0x%4.0x" % spw0.getStatus())
    #print("SpW Link 1 status: 0x%4.0x" % spw1.getStatus())


    


