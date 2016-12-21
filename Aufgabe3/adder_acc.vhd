LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL; 

ENTITY adder_acc IS
  GENERIC(RSTDEF: std_logic := '1');
  PORT (p:   OUT std_logic_vector(43 DOWNTO 0);      -- Result
        a:   IN  std_logic_vector(35 DOWNTO 0);      -- Number to add
        en:  IN  std_logic;                          -- Enable
        rst: IN  std_logic;                          -- Reset
        clk: IN  std_logic);                         -- Clock
END adder_acc;

ARCHITECTURE structure OF adder_acc IS
  
  SIGNAL tmp: std_logic_vector(43 DOWNTO 0);
  
BEGIN

  PROCESS(rst, clk) IS
  BEGIN
    IF rst = RSTDEF THEN
      tmp <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF en = '1' THEN
        tmp <= tmp + a;
      END IF;
    END IF;
  END PROCESS;
  p <= tmp;

END structure;