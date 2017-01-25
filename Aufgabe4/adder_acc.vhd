LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
use ieee.numeric_std.all;

ENTITY adder_acc IS
  GENERIC(RSTDEF: std_logic := '1');
  PORT (p:    OUT std_logic_vector(43 DOWNTO 0);      -- Result
        addr: OUT std_logic_vector(9 downto 0);       -- Address of result
        a:    IN  std_logic_vector(35 DOWNTO 0);      -- Number to add
        en:   IN  std_logic;                          -- Enable
        rst:  IN  std_logic;                          -- Reset
        clk:  IN  std_logic);                         -- Clock
END adder_acc;

ARCHITECTURE structure OF adder_acc IS
  
  CONSTANT ELE: std_logic_vector(3 DOWNTO 0) := "1111"; -- matrix size
  SIGNAL cnt: std_logic_vector(3 DOWNTO 0);              -- intern counter
  SIGNAL tmp: std_logic_vector(43 DOWNTO 0);
  SIGNAL mem_counter: unsigned(9 downto 0);              -- Actual adress of vector
  
BEGIN

  PROCESS(rst, clk) IS
    variable tmp: std_logic_vector(43 DOWNTO 0);
  BEGIN
    IF rst = RSTDEF THEN
      tmp := (OTHERS => '0');
      cnt <= (OTHERS => '1');
      mem_counter <= (OTHERS => '1');
    ELSIF rising_edge(clk) THEN
      IF en = '1' THEN
        IF cnt=ELE THEN
          tmp := (OTHERS => '0');
          mem_counter <= mem_counter + 1;        
        END IF;
        tmp := tmp + a;
        cnt <= cnt + 1;
        p <= tmp;
      END IF;
    END IF;
  END PROCESS;
  addr <= std_logic_vector(mem_counter);

END structure;