----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
--
-- Description: dvid_test
--  Top level design for testing my DVI-D interface
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity dvid_test is
    Port ( clk_in  : in  STD_LOGIC;
           data_p    : out  STD_LOGIC_VECTOR(2 downto 0);
           data_n    : out  STD_LOGIC_VECTOR(2 downto 0);
           clk_p          : out    std_logic;
           clk_n          : out    std_logic;
           reset : in std_logic;
           va : out std_logic_vector(15 downto 0);
           vd : in std_logic_vector(23 downto 0);
           sw : in std_logic_vector(1 downto 0);
           btn : in std_logic_vector(3 downto 0);
           vga_clk : out std_logic;
           ppu_addr : in std_logic_vector(15 downto 0)
       );

end dvid_test;

architecture Behavioral of dvid_test is
   component clocking
   port (
      -- Clock in ports
      clk_in           : in     std_logic;
      -- Clock out ports
      CLK_DVI          : out    std_logic;
      CLK_DVIn         : out    std_logic;
      CLK_VGA          : out    std_logic;
      reset : in std_logic
   );
   end component;
   --component clk_div
   --  generic (
   --  D : natural
   --);
   --  port (
   --  clk_in : in std_logic;
   --  clock_out : out std_logic;
   --  reset : in std_logic
   --);
   --end component;

   COMPONENT dvid
   PORT(
      clk      : IN std_logic;
      clk_n    : IN std_logic;
      clk_pixel: IN std_logic;
      red_p   : IN std_logic_vector(7 downto 0);
      green_p : IN std_logic_vector(7 downto 0);
      blue_p  : IN std_logic_vector(7 downto 0);
      blank   : IN std_logic;
      hsync   : IN std_logic;
      vsync   : IN std_logic;
      red_s   : OUT std_logic;
      green_s : OUT std_logic;
      blue_s  : OUT std_logic;
      clock_s : OUT std_logic
      );
   END COMPONENT;

   COMPONENT lcd
   generic (
      hRez        : natural;
      hStartSync  : natural;
      hEndSync    : natural;
      hMaxCount   : natural;
      hsyncActive : std_logic;

      vRez        : natural;
      vStartSync  : natural;
      vEndSync    : natural;
      vMaxCount   : natural;
      vsyncActive : std_logic
    );

   PORT(
      pixelClock : IN std_logic;
      Red : OUT std_logic_vector(7 downto 0);
      Green : OUT std_logic_vector(7 downto 0);
      Blue : OUT std_logic_vector(7 downto 0);
      hSync : OUT std_logic;
      vSync : OUT std_logic;
      blank : OUT std_logic;
      va : out std_logic_vector(15 downto 0);
      vd : in std_logic_vector(23 downto 0);
      sw : in std_logic_vector(1 downto 0);
      btn : in std_logic_vector(3 downto 0);
      ppu_addr: in std_logic_vector(15 downto 0)
      );
   END COMPONENT;

   signal clk_dvi  : std_logic := clk_in;
   signal clk_dvin : std_logic := not clk_in;
   signal clk_vga  : std_logic := '0';

   signal red     : std_logic_vector(7 downto 0) := (others => '0');
   signal green   : std_logic_vector(7 downto 0) := (others => '0');
   signal blue    : std_logic_vector(7 downto 0) := (others => '0');
   signal hsync   : std_logic := '0';
   signal vsync   : std_logic := '0';
   signal blank   : std_logic := '0';
   signal red_s   : std_logic;
   signal green_s : std_logic;
   signal blue_s  : std_logic;
   signal clock_s : std_logic;
begin

  --clk_div_inst: clk_div generic map (
  --  D => 5
  --)
  --port map (
  --clk_in => clk_dvin,
  --clock_out => clk_vga,
  --reset => reset
  --);
clocking_inst : clocking port map (
      clk_in   => clk_in,
      -- Clock out ports
      --CLK_DVI  => clk_dvi,  -- for 640x480@60Hz : 125MHZ
      --CLK_DVIn => clk_dvin, -- for 640x480@60Hz : 125MHZ, 180 degree phase shift
      CLK_VGA  => clk_vga,   -- for 640x480@60Hz : 25MHZ
      reset => reset
    );

  vga_clk <= clk_vga;

Inst_dvid: dvid PORT MAP(
      clk       => clk_dvi,
      clk_n     => clk_dvin,
      clk_pixel => clk_vga,
      red_p     => red,
      green_p   => green,
      blue_p    => blue,
      blank     => blank,
      hsync     => hsync,
      vsync     => vsync,
      -- outputs to TMDS drivers
      red_s     => red_s,
      green_s   => green_s,
      blue_s    => blue_s,
      clock_s   => clock_s
   );

OBUFDS_blue  : OBUFDS port map ( O  => DATA_P(0), OB => DATA_N(0), I  => blue_s  );
OBUFDS_red   : OBUFDS port map ( O  => DATA_P(1), OB => DATA_N(1), I  => green_s );
OBUFDS_green : OBUFDS port map ( O  => DATA_P(2), OB => DATA_N(2), I  => red_s   );
OBUFDS_clock : OBUFDS port map ( O  => CLK_P, OB => CLK_N, I  => clock_s );
    -- generic map ( IOSTANDARD => "DEFAULT")

Inst_vga: lcd GENERIC MAP (
      -- hRez       => 640, hStartSync => 656, hEndSync   => 752, hMaxCount  => 800, hsyncActive => '0',
      -- vRez       => 400, vStartSync => 412, vEndSync   => 414, vMaxCount  => 449, vsyncActive => '1'
      hRez       => 640, hStartSync => 656, hEndSync   => 752, hMaxCount  => 800, hsyncActive => '0',
      vRez       => 480, vStartSync => 490, vEndSync   => 492, vMaxCount  => 525, vsyncActive => '1'
   ) PORT MAP(
      pixelClock => clk_vga,
      Red        => red,
      Green      => green,
      Blue       => blue,
      hSync      => hSync,
      vSync      => vSync,
      blank      => blank,
      va => va,
      vd => vd,
      sw => sw,
      btn => btn,
      ppu_addr => ppu_addr
   );
end Behavioral;
