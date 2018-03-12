-------------------------------------------------------------------------------
-- Title      : Testbench for design "beacon_robot"
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2011 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.hdlc_pkg.all;
use work.bus_pkg.all;
use work.reg_file_pkg.all;
use work.fifo_sync_pkg.all;
use work.reset_pkg.all;
use work.uart_pkg.all;
use work.utils_pkg.all;
use work.uart_tb_pkg.all;

-------------------------------------------------------------------------------
entity toplevel_tb is
end toplevel_tb;

-------------------------------------------------------------------------------
architecture tb of toplevel_tb is

  signal clk  : std_logic := '0';
  signal rsrx : std_logic := '1';
  signal rstx : std_logic := '1';
  signal led  : std_logic_vector(7 downto 0);
  signal sw   : std_logic_vector(7 downto 0);
  signal so   : std_logic_vector(1 downto 0);
  signal do   : std_logic_vector(1 downto 0);
  signal si   : std_logic_vector(1 downto 0);
  signal di   : std_logic_vector(1 downto 0);

begin

  toplevel_1 : entity work.toplevel
    generic map (
      RESET_IMPL => sync)
    port map (
      so   => so,
      do   => do,
      si   => si,
      di   => di,
      rsrx => rsrx,
      rstx => rstx,
      led  => led,
      sw   => sw,
      clk  => clk);

  -- clock generation
  Clk <= not Clk after 10 ns;

  -- loopback
  si(0) <= so(1);
  di(0) <= do(1);

  si(1) <= so(0);
  di(1) <= do(0);

  process
  begin
    wait for 25 ns;
    --reset_n <= '0';

    wait for 5 us;
    -- enable port 0    
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"20", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"12", 250000);
    uart_transmit(rsrx, "0" & x"04", 250000);
    uart_transmit(rsrx, "0" & x"03", 250000);
    uart_transmit(rsrx, "0" & x"4d", 250000);  -- crc good

    wait for 100 us;
    -- enable port 1
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"20", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"22", 250000);
    uart_transmit(rsrx, "0" & x"04", 250000);
    uart_transmit(rsrx, "0" & x"03", 250000);
    uart_transmit(rsrx, "0" & x"ac", 250000);  -- crc good

    wait for 100 us;
    -- read 0x0011 - port 0 status
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"10", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"11", 250000);
    uart_transmit(rsrx, "0" & x"d5", 250000);  -- crc good

    wait for 100 us;
    -- send 0x41 over port 1
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"20", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"20", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"41", 250000);
    uart_transmit(rsrx, "0" & x"e7", 250000);  -- crc good

    wait for 100 us;
    -- send EOP over port 1
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"20", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"20", 250000);
    uart_transmit(rsrx, "0" & x"01", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"32", 250000);  -- crc good


    
    wait for 100 us;
    -- read data from port 0 (0x0010)
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"10", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"10", 250000);
    uart_transmit(rsrx, "0" & x"d2", 250000);  -- crc good

    wait for 100 us;
    -- read data from port 0 (0x0010)
    uart_transmit(rsrx, "0" & x"7e", 250000);
    uart_transmit(rsrx, "0" & x"10", 250000);
    uart_transmit(rsrx, "0" & x"00", 250000);
    uart_transmit(rsrx, "0" & x"10", 250000);
    uart_transmit(rsrx, "0" & x"d2", 250000);  -- crc good


    wait for 100 ms;
  end process;

end tb;

