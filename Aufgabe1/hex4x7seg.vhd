
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

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
  constant M2_14_N: integer := 15;                    -- number of bits
  constant M2_14_M: integer := 16384;                 -- mod-M
  constant M4_N: integer := 3;                        -- number of bits
  constant M4_M: integer := 4;                        -- mod-M
  
  signal m2_14_r_reg: unsigned(M2_14_N-1 downto 0);   -- intern register for frequency divider
  signal m2_14_r_next: unsigned(M2_14_M-1 downto 0);  -- intern register for frequency divider
  signal clock_out: std_logic;                        -- divided frequency
  
  signal m4_r_reg: unsigned(M4_N-1 downto 0);         -- intern register for frequency divider
  signal m4_r_next: unsigned(M4_M-1 downto 0);        -- intern register for frequency divider
  signal m4_out: std_logic_vector (M4_N-1 downto 0)   -- output of Modulo-4-Counter
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
    -- next-state logic
    m2_14_r_next <= (others=>'0') when m2_14_r_reg=(M2_14_M-1) else m2_14_r_reg + 1;
    -- output logic
    clk_out <= '1' when m2_14_r_reg=(M2_14_M-1) else '0';
  end process; 
   
  -- Modulo-4-Zaehler als Prozess
  process (clock_out, rst)
  begin
    -- register
    if(rst = '1') then
      m4_r_reg <= (others=>'0');
    elsif rising_edge(clk) then
      m4_r_reg <= m4_r_next;
    end if;
    -- next-state logic
    m4_r_next <= (others=>'0') when m4_r_reg=(M4_M-1) else m4_r_reg + 1;
    -- output logic
    m4_out <= std_logic_vector(m4_r_reg); 
  end process;

  -- 1-aus-4-Dekoder als selektierte Signalzuweisung
  case m4_out is
    when "00" => an <= "0001";
    when "01" => an <= "0010";
    when "10" => an <= "0100";
    when "11" => an <= "1000";
    when others => an <= "0000";
  end case;

  -- 1-aus-4-Multiplexer als selektierte Signalzuweisung

   
  -- 7-aus-4-Dekoder als selektierte Signalzuweisung
   
   
  -- 1-aus-4-Multiplexer als selektierte Signalzuweisung
  if m4_out = "00" and dpin(0) = '1' then
    dp = '1';
  elsif m4_out = "01" and dpin(1) = '1' then
    dp = '1';
  elsif m4_out = "10" and dpin(2) = '1' then 
    dp = '1';
  elsif m4_out = "11" and dpin(3) = '1' then 
    dp = '1';
  else
    dp = '0';
  end if;
--END struktur;
end;