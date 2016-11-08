

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
  constant CLOCK_DIVIDER_N: natural := 16384; 							-- mod-N for clock divider
  constant M4_COUNTER_N: natural := 4;                                  -- mod-N for m4-counter
  constant M4_COUNTER_BITS: integer := 2;                               -- number of bits
  
  signal clock_divider_counter: integer range 0 to CLOCK_DIVIDER_N-1;   -- counter for the clock divider
  signal clock_divider_out: std_logic;                                  -- clock divider output (rising edge)
  
  signal m4_out: std_logic_vector (M4_COUNTER_BITS-1 downto 0):= (others => '0');  -- output of Modulo-4-Counter

  signal oneOutFourMux: std_logic_vector(3 downto 0):= (others => '0'); -- 1-out-4-4bit-mux output
  
  signal an_sel: std_logic_vector( 3 DOWNTO 0):= (others => '0');       -- selector for an
  
  signal dpin_m4_out: std_logic_vector( 5 DOWNTO 0):= (others => '0');  -- concatenation of dpin and m4_out
--BEGIN
begin

  -- Modulo-2**14-Zaehler als Prozess
  process (rst, clk) begin
    if rst='1' then
      clock_divider_counter <= 0;
	  clock_divider_out <= '0';
	elsif rising_edge(clk) then
	  clock_divider_out <= '0';
      if clock_divider_counter=CLOCK_DIVIDER_N-1 then
        clock_divider_counter <= 0;
		clock_divider_out <= '1';
      else
        clock_divider_counter <= clock_divider_counter + 1;
      end if;
    end if;
  end process;
   
  -- Modulo-4-Zaehler als Prozess
  process (rst, clock_divider_out) begin
    if rst='1' then
	  m4_out <= (others => '0');
	elsif rising_edge(clock_divider_out) then
	  if m4_out=M4_COUNTER_N-1 then
	    m4_out <= (others => '0');
	  else
	    m4_out <= m4_out + 1;
	  end if;
	end if;
  end process;

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

--END struktur;
end;