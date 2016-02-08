-------------------------------------------------------------------------------
-- Demonstration for using Loa modules in the new structure
--
-- Sytem contains a HDLC busmaster, a peripheral register for IO and a PWM
-- generator.
--
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
use work.pwm_pkg.all;
use work.pwm_module_pkg.all;
use work.ws2812_pkg.all;

entity toplevel is
  generic (RESET_IMPL : reset_type := sync);
  port(clk    : in  std_logic;          -- 50MHz
       rsrx   : in  std_logic;
       rstx   : out std_logic;
       pwm1   : out std_logic;
       pwm1n  : out std_logic;
       dac    : out std_logic_vector(2 downto 0);
       led    : out std_logic_vector(7 downto 0);
       sw     : in  std_logic_vector(7 downto 0);
       ws2812 : out std_logic
       );
end toplevel;

architecture Behavioral of toplevel is
  signal reset          : std_logic;
  signal bus_to_master  : busmaster_in_type  := (data => (others => '0'));
  signal master_to_bus  : busmaster_out_type := (addr => (others => '0'), data => (others => '0'), re => '0', we => '0');
  signal reg_to_master  : busdevice_out_type := (data => (others => '0'));
  signal pwm1_to_master : busdevice_out_type := (data => (others => '0'));
  signal dds_to_master  : busdevice_out_type := (data => (others => '0'));
  signal ws_to_master   : busdevice_out_type := (data => (others => '0'));

  signal dds_out : std_logic_vector(15 downto 0);
  signal reg_out : std_logic_vector(15 downto 0);
  signal reg_in  : std_logic_vector(15 downto 0);

  signal pwm1_s : std_logic;

  signal pixels_regfile   : reg_file_type(31 downto 0);
  signal pixels           : ws2812_16x1_in_type;
  signal ws2812_in        : ws2812_in_type;
  signal ws2812_out       : ws2812_out_type;
  signal ws2812_chain_out : ws2812_chain_out_type;

begin
  -----------------------------------------------------------------------------
  -- Reset generator
  -----------------------------------------------------------------------------
  reset_gen_inst : entity work.reset_gen
    port map (
      reset => reset,
      clk   => clk);

  -----------------------------------------------------------------------------
  -- LOA Bus & HDLC Busmaster
  -- here we collect the data-outputs of the devices
  -----------------------------------------------------------------------------
  busmaster : entity work.hdlc_busmaster_with_support
    generic map (
      DIV_RX     => 87,
      DIV_TX     => 434,
      RESET_IMPL => RESET_IMPL)
    port map (
      rx    => rsrx,
      tx    => rstx,
      bus_o => master_to_bus,
      bus_i => bus_to_master,
      reset => reset,
      clk   => clk);

  bus_to_master.data <= reg_to_master.data or
                        pwm1_to_master.data or
                        dds_to_master.data or
                        ws_to_master.data;

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
      reset  => reset,
      clk    => clk);

  -----------------------------------------------------------------------------
  -- IOs interconnect to LEDs and Switches
  -----------------------------------------------------------------------------
  reg_in          <= x"00" & sw;
  led(7 downto 0) <= reg_out(7 downto 0);

  -----------------------------------------------------------------------------
  -- PWM and deadtime module
  -----------------------------------------------------------------------------
  pwm_module_1 : entity work.pwm_module
    generic map (
      BASE_ADDRESS => 16#0010#,
      WIDTH        => 12,
      PRESCALER    => 1)
    port map (
      pwm_p => pwm1_s,
      bus_o => pwm1_to_master,
      bus_i => master_to_bus,
      reset => '0',
      clk   => clk);

  pwm1  <= not pwm1_s;
  pwm1n <= not pwm1_s;

  -----------------------------------------------------------------------------
  -- DDS module
  -----------------------------------------------------------------------------
  dds_module_1 : entity work.dds_module
    generic map (
      BASE_ADDRESS => 16#400#,          -- has do be alligned, due to internal
      -- bram
      RESET_IMPL   => RESET_IMPL)
    port map (
      bus_o => dds_to_master,
      bus_i => master_to_bus,
      dout  => dds_out,
      reset => reset,
      clk   => clk);

  dac(2 downto 0) <= dds_out(15 downto 13);

  -----------------------------------------------------------------------------
  -- WS2812 Driver (8 x 1)
  -----------------------------------------------------------------------------
  reg_file_1 : entity work.reg_file
    generic map (
      BASE_ADDRESS => 16#1000#,
      REG_ADDR_BIT => 5,
      RESET_IMPL   => RESET_IMPL)
    port map (
      bus_o => ws_to_master,
      bus_i => master_to_bus,
      reg_o => pixels_regfile,
      reg_i => pixels_regfile,
      reset => reset,
      clk   => clk);

  gen_addierer : for i in 0 to 15 generate
    pixels.pixel(i) <= pixels_regfile(i*2+1)(7 downto 0) & pixels_regfile(i*2);
  end generate gen_addierer;

  pixels.refresh <= '1';

  ws2812_16x1_1 : entity work.ws2812_16x1
    generic map (
      RESET_IMPL => RESET_IMPL)
    port map (
      pixels     => pixels,
      ws2812_in  => ws2812_in,
      ws2812_out => ws2812_out,
      reset      => reset,
      clk        => clk);

  ws2812_1 : entity work.ws2812
    generic map (
      RESET_IMPL => RESET_IMPL)
    port map (
      ws2812_in        => ws2812_in,
      ws2812_out       => ws2812_out,
      ws2812_chain_out => ws2812_chain_out,
      reset            => reset,
      clk              => clk);

  ws2812 <= ws2812_chain_out.d;

end Behavioral;

