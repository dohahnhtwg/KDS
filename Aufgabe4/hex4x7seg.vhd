

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
  constant CLOCK_DIVIDER_N: natural := 2**14; 							                   -- mod-N for clock divider
  constant CLOCK_DIVIDER_N_BITS: integer := 14; 							                -- mod-N for clock divider
  constant M4_COUNTER_BITS: integer := 2;                                            -- number of bits
  
  signal clock_divider_counter: std_logic_vector (CLOCK_DIVIDER_N_BITS-1 downto 0);  -- output of Modulo-4-Counter
  signal clock_divider_out: std_logic;                                               -- clock divider output (rising edge)
  
  signal m4_out: std_logic_vector (M4_COUNTER_BITS-1 downto 0);                      -- output of Modulo-4-Counter

  signal oneOutFourMux: std_logic_vector(3 downto 0);                                -- 1-out-4-4bit-mux output
  
  signal an_sel: std_logic_vector( 3 DOWNTO 0);                                      -- selector for an
--BEGIN
begin

  -- Modulo-2**14-Zaehler als Prozess
  process (rst, clk) begin
    if rst=RSTDEF then
      clock_divider_counter <= (others => '0');
      clock_divider_out <= '0';
    elsif rising_edge(clk) then
      clock_divider_out <= '0';
      if clock_divider_counter = CLOCK_DIVIDER_N - 1 then
        clock_divider_out <= '1';
      end if;
      clock_divider_counter <= clock_divider_counter + 1;
    end if;
  end process;
   
  -- Modulo-4-Zaehler als Prozess
  process (rst, clk) begin
    if rst=RSTDEF then
	  m4_out <= (others => '0');
	elsif rising_edge(clk) then
     if clock_divider_out='1' then
	    m4_out <= m4_out + 1;
     end if;
	end if;
  end process;

  -- 1-aus-4-Dekoder als selektierte Signalzuweisung
  
  with m4_out select
    an_sel <= "0111" when "00",
              "1011" when "01",
              "1101" when "10",
              "1110" when others;
  
  an <= "1111" when rst = RSTDEF else an_sel;

  -- 1-aus-4-Multiplexer als selektierte Signalzuweisung
  with m4_out select
    oneOutFourMux <= data(15 downto 12)   when "00",
                     data(11 downto 8)   when "01",
                     data(7 downto 4)  when "10",
                     data(3 downto 0) when others;
   
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

  WITH m4_out SELECT
    dp <= NOT dpin(3) WHEN "00",
          NOT dpin(2) WHEN "01",
          NOT dpin(1) WHEN "10",
          NOT dpin(0) WHEN OTHERS;
            
--END struktur;
end;