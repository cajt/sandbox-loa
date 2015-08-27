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

entity toplevel is
  generic (RESET_IMPL : reset_type := sync);
  port(clk   : in  std_logic;           -- 50MHz
       rsrx  : in  std_logic;
       rstx  : out std_logic;
       pwm1  : out std_logic;
       pwm1n : out std_logic;
       dac   : out std_logic_vector(2 downto 0);
       led   : out std_logic_vector(7 downto 0);
       sw    : in  std_logic_vector(7 downto 0)
       );
end toplevel;

architecture Behavioral of toplevel is
  type fifo_link_8bit_type is record
    data   : std_logic_vector(7 downto 0);
    enable : std_logic;
    empty  : std_logic;
  end record;

  signal reset            : std_logic;
  signal bus_o            : busmaster_out_type;
  signal bus_i            : busmaster_in_type;
  signal rx_to_dec        : hdlc_dec_in_type   := (data => (others => '0'), enable => '0');
  signal dec_to_busmaster : hdlc_dec_out_type  := (data => (others => '0'), enable => '0');
  signal bus_to_master    : busmaster_in_type  := (data => (others => '0'));
  signal master_to_bus    : busmaster_out_type := (addr => (others => '0'), data => (others => '0'), re => '0', we => '0');
  signal reg_to_master    : busdevice_out_type := (data => (others => '0'));
  signal pwm1_to_master   : busdevice_out_type := (data => (others => '0'));
  signal dds_to_master    : busdevice_out_type := (data => (others => '0'));

  -- Connections components used for HDLC link
  signal master_to_enc        : hdlc_enc_in_type    := (data => (others => '0'), enable => '0');
  signal enc_to_fifo          : hdlc_enc_out_type   := (data => (others => '0'), enable => '0');
  signal fifo_to_uart_tx      : fifo_link_8bit_type := (data => (others => '0'), enable => '0', empty => '0');
  signal enc_busy             : std_logic           := '0';
  signal clk_rx_en, clk_tx_en : std_logic;

  signal dds_out : std_logic_vector(15 downto 0);

  signal reg_out : std_logic_vector(15 downto 0);
  signal reg_in  : std_logic_vector(15 downto 0);

  signal pwm1_s : std_logic;

begin
  -----------------------------------------------------------------------------
  -- Reset generator
  -----------------------------------------------------------------------------
  reset_gen_inst : entity work.reset_gen
    port map (
      reset => reset,
      clk   => clk);

  -----------------------------------------------------------------------------
  --  Baudrate Generator 
  -----------------------------------------------------------------------------
  baudrate_rx_gen_inst : entity work.clock_divider
    generic map(DIV => 87)
    port map(
      clk       => clk,
      clk_out_p => clk_rx_en);

  baudrate_tx_gen_inst : entity work.clock_divider
    generic map(DIV => 434)
    port map(
      clk       => clk,
      clk_out_p => clk_tx_en);

  -----------------------------------------------------------------------------
  -- UART RX
  -----------------------------------------------------------------------------
  uart_rx_inst : entity work.uart_rx
    generic map (RESET_IMPL => RESET_IMPL)
    port map(
      rxd_p     => rsrx,
      disable_p => '0',
      data_p    => rx_to_dec.data,
      we_p      => rx_to_dec.enable,
      error_p   => open,
      full_p    => '0',
      clk_rx_en => clk_rx_en,
      reset     => reset,
      clk       => clk);

  -----------------------------------------------------------------------------
  --  Decoder
  -----------------------------------------------------------------------------
  hdlc_dec_inst : entity work.hdlc_dec
    port map(
      din_p  => rx_to_dec,
      dout_p => dec_to_busmaster,
      clk    => clk);

  -----------------------------------------------------------------------------
  -- Busmaster
  -----------------------------------------------------------------------------
  bus_master_inst : entity work.hdlc_busmaster
    port map(
      din_p  => dec_to_busmaster,
      dout_p => master_to_enc,
      bus_o  => master_to_bus,
      bus_i  => bus_to_master,
      clk    => clk);

  -----------------------------------------------------------------------------
  -- Encoder
  -----------------------------------------------------------------------------
  hdlc_enc_inst : entity work.hdlc_enc
    port map(
      din_p  => master_to_enc,
      dout_p => enc_to_fifo,
      busy_p => open,
      clk    => clk);

  -----------------------------------------------------------------------------
  -- Transmit FIFO
  -----------------------------------------------------------------------------
  tx_fifo_inst : entity work.fifo_sync
    generic map(
      data_width    => 8,
      address_width => 5)
    port map(
      di    => enc_to_fifo.data,
      wr    => enc_to_fifo.enable,
      full  => open,
      do    => fifo_to_uart_tx.data,
      rd    => fifo_to_uart_tx.enable,
      empty => fifo_to_uart_tx.empty,
      valid => open,
      clk   => clk);

  -----------------------------------------------------------------------------
  -- UART TX
  -----------------------------------------------------------------------------
  uart_tx_inst : entity work.uart_tx
    generic map (RESET_IMPL => RESET_IMPL)
    port map(
      txd_p     => rstx,
      busy_p    => open,
      data_p    => fifo_to_uart_tx.data,
      empty_p   => fifo_to_uart_tx.empty,
      re_p      => fifo_to_uart_tx.enable,
      clk_tx_en => clk_tx_en,
      reset     => reset,
      clk       => clk);

  -----------------------------------------------------------------------------
  -- LOA Bus
  -- here we collect the data-outputs of the devices
  -----------------------------------------------------------------------------
  bus_to_master.data <= reg_to_master.data or
                        pwm1_to_master.data or
                        dds_to_master.data;

  -----------------------------------------------------------------------------
  -- Input & output periphery register 
  -----------------------------------------------------------------------------
  reg_inst : entity work.peripheral_register
    generic map(
      BASE_ADDRESS => 16#0000#)
    port map(
      dout_p => reg_out,
      din_p  => reg_in,
      bus_o  => reg_to_master,
      bus_i  => master_to_bus,
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


end Behavioral;

