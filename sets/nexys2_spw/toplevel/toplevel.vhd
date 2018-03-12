-------------------------------------------------------------------------------
-- Demonstration using two SpW interfaces
---
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library work;
use work.hdlc_pkg.all;
use work.bus_pkg.all;
use work.reset_pkg.all;
use work.reset_gen_pkg.all;
use work.reg_file_pkg.all;
use work.fifo_sync_pkg.all;
use work.utils_pkg.all;
use work.uart_pkg.all;
use work.spw_node_pkg.all;

entity toplevel is
  generic (RESET_IMPL : reset_type := sync);
  port(
    so : out std_logic_vector(1 downto 0);
    do : out std_logic_vector(1 downto 0);
    si : in  std_logic_vector(1 downto 0);
    di : in  std_logic_vector(1 downto 0);

    rsrx : in  std_logic;
    rstx : out std_logic;

    led : out std_logic_vector(7 downto 0);
    sw  : in  std_logic_vector(7 downto 0);

    clk : in std_logic
    );
end toplevel;

architecture Behavioral of toplevel is
  signal reset : std_logic;

  signal bus_to_master  : busmaster_in_type  := (data => (others => '0'));
  signal master_to_bus  : busmaster_out_type := (addr => (others => '0'), data => (others => '0'), re => '0', we => '0');
  signal reg_to_master  : busdevice_out_type := (data => (others => '0'));
  signal spw0_to_master : busdevice_out_type := (data => (others => '0'));
  signal spw1_to_master : busdevice_out_type := (data => (others => '0'));

  signal reg_out : std_logic_vector(15 downto 0);
  signal reg_in  : std_logic_vector(15 downto 0);

begin
  -----------------------------------------------------------------------------
  -- Reset generator
  -----------------------------------------------------------------------------
  reset_gen_inst : entity work.reset_gen
    port map (
      reset => reset,
      clk   => clk);

  -----------------------------------------------------------------------------
  -- HDLC Busmaster with UART
  -----------------------------------------------------------------------------

  hdlc_busmaster_with_support : entity work.hdlc_busmaster_with_support
    generic map (
      DIV_RX     => 40,
      DIV_TX     => 200,
      RESET_IMPL => RESET_IMPL)
    port map (
      rx    => rsrx,
      tx    => rstx,
      bus_o => master_to_bus,
      bus_i => bus_to_master,
      reset => reset,
      clk   => clk);

  -----------------------------------------------------------------------------
  -- LOA Bus
  -- here we collect the data-outputs of the devices
  -----------------------------------------------------------------------------
  bus_to_master.data <= reg_to_master.data or
                        spw0_to_master.data or
                        spw1_to_master.data;

  -----------------------------------------------------------------------------
  -- Input & output periphery register 
  -----------------------------------------------------------------------------
  reg_inst : entity work.peripheral_register
    generic map(
      BASE_ADDRESS => 16#0000#,
      RESET_IMPL   => RESET_IMPL)
    port map(
      dout_p => reg_out,
      din_p  => reg_in,
      bus_o  => reg_to_master,
      bus_i  => master_to_bus,
      reset => reset, 
      clk    => clk);

  -----------------------------------------------------------------------------
  -- IOs interconnect to LEDs and Switches
  -----------------------------------------------------------------------------
  reg_in          <= x"00" & sw;
  led(7 downto 0) <= reg_out(7 downto 0);


  -----------------------------------------------------------------------------
  -- SPW 0 Interface
  -----------------------------------------------------------------------------
  spw_node_0 : entity work.spw_node
    generic map (
      BASE_ADDRESS => 16#0010#,
      RESET_IMPL   => RESET_IMPL)
    port map (
      do_p  => do(0),
      so_p  => so(0),
      di_p  => di(0),
      si_p  => si(0),
      bus_o => spw0_to_master,
      bus_i => master_to_bus,
      reset => reset,
      clk   => clk);

  -----------------------------------------------------------------------------
  -- SPW 1 Interface
  -----------------------------------------------------------------------------
  spw_node_1 : entity work.spw_node
    generic map (
      BASE_ADDRESS => 16#0020#,
      RESET_IMPL   => RESET_IMPL)
    port map (
      do_p  => do(1),
      so_p  => so(1),
      di_p  => di(1),
      si_p  => si(1),
      bus_o => spw1_to_master,
      bus_i => master_to_bus,
      reset => reset,
      clk   => clk);

end Behavioral;


