LIBBUILD=../../../library-builder/scripts/lbuild
LOA_HDL_DIR=../../../loa-hdl
LOA_VENDOR_DIR=../../../loa-vendor

loa:
	$(LIBBUILD) -r $(LOA_HDL_DIR)/loa-hdl.lb -r $(LOA_VENDOR_DIR)/loa-vendor.lb  -c modules_from_loa.lb

prog:
	~/projects/fpga_misc/nexys2prog/nexys2prog -v toplevel/ise/work/toplevel.bit 

clean:
	rm -rf hdl
	rm -rf tb
	


