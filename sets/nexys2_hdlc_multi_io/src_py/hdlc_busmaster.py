#!/usr/bin/env python 

import serial
import CrcMoose

class hdlc_busmaster:
    def __init__(self, port):
        self.s = serial.Serial(port, baudrate=115200, timeout=0.01, parity=serial.PARITY_ODD)

    def read(self, addr):
        cmd = "\x10" + chr((addr >> 8) & 0xff) + chr((addr) & 0xff)  
        cmd = "\x7e" + cmd + chr(CrcMoose.CRC8_SMBUS.calcString(cmd))
        self.s.write(cmd)


        reply = self.get_frame()
        #print reply.__repr__()
        # write read encoded data
        #assert(len(reply) == 4)
        #assert(reply[0] == "\x7e")
        #assert(hex(CrcMoose.CRC8_SMBUS.calcString(reply[1:4]) == reply[4]))
        data = (ord(reply[1]) << 8) + ord(reply[2])
        return data

    def write(self, addr, data):
        cmd = "\x20" + chr((addr >> 8) & 0xff) + chr((addr) & 0xff) + chr((data >> 8) & 0xff) + chr((data) & 0xff) 
        cmd = "\x7e" + self.encode( cmd + chr(CrcMoose.CRC8_SMBUS.calcString(cmd)))
        #print cmd.__repr__()
        self.s.write(cmd), " -> ",

        reply = self.get_frame()
        #print reply.__repr__()
        assert(len(reply) == 2)
        assert(reply[0] == "\x21")
        assert(reply[1] == "\xe7")


    def encode(self, x):
        o = ""
        for c in x:
            if c == "\x7e":
                o += "\x7d\x5e"
            elif c == "\x7d":
                o += "\x7d\x5d"
            else:
                o += c
        return o

    def get_frame(self):
        o = ""
        while True:
            c = self.s.read(1)
            if c == "\x7e": # got start
                break

        c = self.s.read(1)
        o += c
        if c == "\x11": # read reply
            for i in range(5):
                c = self.s.read(1)
                if c == "\x7e":
                    c = self.s.read(1)
                    if c == "\x5e":
                        o += "\x7e"
                    elif c == "\x5d":
                        o += "\x7d"
                else:
                    o += c
            assert(hex(CrcMoose.CRC8_SMBUS.calcString(o[0:2]) == o[3]))

        elif c == "\x21": # write ack
            c = self.s.read(1)
            o += c
            assert(c == "\xe7")
            #print "valid write ack"

        elif c == "\x03":
            c = self.s.read(1)
            o += c
            #print "Bad crc"
        return o
                
       

if __name__ == "__main__":
    import time
    import sys 

    if len(sys.argv) == 1:
        port = "/dev/ttyUSB0"
    else:
        port = sys.argv[1]

    loa = hdlc_busmaster(port)

    print "Read from 0x0000: ",
    sw = loa.read(0x0000)
    print sw
    print "Wrtie 0x5555 to 0x0000"
    loa.write(0x0000, 0x5555)
    time.sleep(0.25)
    print "Wrtie 0xAAAA to 0x0000"
    loa.write(0x0000, 0xaaaa)

