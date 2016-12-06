LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY flip_flop IS
  GENERIC(RSTDEF:  std_logic := '1');
  PORT(rst:    IN  std_logic;  -- reset, RSTDEF active
       clk:    IN  std_logic;  -- clock, rising edge
       din:    IN  std_logic;  -- data bit, input
       dout:   OUT std_logic); -- data bit, output
END flip_flop;


ARCHITECTURE behavioral OF flip_flop IS


BEGIN


  
  process (rst, clk) is
  begin
    if rst=RSTDEF then
      dout <= '0';
    elsif rising_edge(clk) then
      dout <= din;
    end if;
  end process;

END behavioral;