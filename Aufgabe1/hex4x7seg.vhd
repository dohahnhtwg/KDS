

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

ENTITY hex4x7seg IS
   GENERIC(RSTDEF:  std_logic := '0');
   PORT(rst:   IN  std_logic;                       -- reset,           active RSTDEF
        clk:   IN  std_logic;                       -- clock,           rising edge
        en:    IN  std_logic;                       -- enable,          active high
        swrst: IN  std_logic;                       -- software reset,  active RSTDEF
        data:  IN  std_logic_vector(15 DOWNTO 0);   -- data input,      positiv logic
        dpin:  IN  std_logic_vector( 3 DOWNTO 0);   -- 4 decimal point, active high
        an:    OUT std_logic_vector( 3 DOWNTO 0);   -- 4 digit enable (anode control) signals,      active low
        dp:    OUT std_logic;                       -- 1 decimal point output,                      active low
        seg:   OUT std_logic_vector( 7 DOWNTO 1));  -- 7 FPGA connections to seven-segment display, active low
END hex4x7seg;

--ARCHITECTURE struktur OF hex4x7seg IS
architecture arch of hex4x7seg is
  -- hier sind benutzerdefinierte Konstanten und Signale einzutragen
  constant M2_14_N: integer := 15;                                      -- number of bits
  constant M2_14_M: integer := 16384;                                   -- mod-M
  constant M4_N: integer := 2;                                          -- number of bits
  constant M4_M: integer := 4;                                          -- mod-M
  
  signal m2_14_r_reg: unsigned(M2_14_N-1 downto 0):= (others => '0');   -- intern register for frequency divider
  signal m2_14_r_next: unsigned(M2_14_N-1 downto 0):= (others => '0');  -- intern register for frequency divider
  signal clock_out: std_logic;                                          -- divided frequency
  
  signal m4_r_reg: unsigned(M4_N-1 downto 0):= (others => '0');         -- intern register for frequency divider
  signal m4_r_next: unsigned(M4_N-1 downto 0):= (others => '0');        -- intern register for frequency divider
  signal m4_out: std_logic_vector (M4_N-1 downto 0):= (others => '0');  -- output of Modulo-4-Counter

  signal oneOutFourMux: std_logic_vector(3 downto 0):= (others => '0'); -- 1-out-4-4bit-mux output
  
  signal an_sel: std_logic_vector( 3 DOWNTO 0):= (others => '0');       -- selector for an
  
  signal dpin_m4_out: std_logic_vector( 5 DOWNTO 0):= (others => '0');  -- concatenation of dpin and m4_out
--BEGIN
begin

  -- Modulo-2**14-Zaehler als Prozess
  process (clk, rst)
  begin
    -- register
    if(rst = '1') then
      m2_14_r_reg <= (others=>'0');
    elsif rising_edge(clk) then
      m2_14_r_reg <= m2_14_r_next;
    end if;
  end process;

  -- next-state logic
  m2_14_r_next <= (others=>'0') when m2_14_r_reg=(M2_14_M-1) else m2_14_r_reg + 1;
  -- output logic
  clock_out <= '1' when m2_14_r_reg=(M2_14_M-1) else '0';
   
  -- Modulo-4-Zaehler als Prozess
  process (clock_out, rst)
  begin
    -- register
    if(rst = '1') then
      m4_r_reg <= (others=>'0');
    elsif rising_edge(clock_out) then
      m4_r_reg <= m4_r_next;
    end if; 
  end process;
  -- next-state logic
  m4_r_next <= (others=>'0') when m4_r_reg=(M4_M-1) else m4_r_reg + 1;
  -- output logic
  m4_out <= std_logic_vector(m4_r_reg);

  -- 1-aus-4-Dekoder als selektierte Signalzuweisung
  
  with m4_out select
    an_sel <= "1110" when "00",
              "1101" when "01",
              "1011" when "10",
              "0111" when others;
  
  an <= an_sel when rst='0' else "1111";

  -- 1-aus-4-Multiplexer als selektierte Signalzuweisung
  with m4_out select
    oneOutFourMux <= data(3 downto 0)   when "00",
                     data(7 downto 4)   when "01",
                     data(11 downto 8)  when "10",
                     data(15 downto 12) when others;
   
  -- 7-aus-4-Dekoder als selektierte Signalzuweisung
  with oneOutFourMux select
    seg <= "0000001" when "0000",
           "1001111" when "0001",
           "0010010" when "0010",
           "0000110" when "0011",
           "1001100" when "0100",
           "0100100" when "0101",
           "0100000" when "0110",
           "0001111" when "0111",
           "0000000" when "1000",
           "0000100" when "1001",
           "0001000" when "1010", --a
           "1100000" when "1011", --b
           "0110001" when "1100", --c
           "1000010" when "1101", --d
           "0110000" when "1110", --e
           "0111000" when others; --f 

  -- 1-aus-4-Multiplexer als selektierte Signalzuweisung
  dpin_m4_out <= dpin & m4_out;
  with dpin_m4_out select
    dp <= '0' when "001100",
          '0' when "001101",
          '0' when "110010",
          '0' when "110011",
          '0' when "111100",
          '0' when "111101",
          '0' when "111110",
          '0' when "111111",
          '1' when others;
          
  
  --dp <= '0' when (dpin = "0011" and (m4_out = "00" or m4_out = "01")) or (dpin = "1100" and (m4_out = "10" or m4_out = "11")) or dpin = "1111" else
  --      '1';

--END struktur;
end;