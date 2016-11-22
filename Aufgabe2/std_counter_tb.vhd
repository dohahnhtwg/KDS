LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY std_counter_test IS
  -- empty
END std_counter_test;

ARCHITECTURE test OF std_counter_test IS
  CONSTANT RSTDEF: std_ulogic := '1';
  CONSTANT tpd: time := 20 ns; -- 1/50 MHz
  CONSTANT CNTLEN: natural := 4;

  COMPONENT std_counter IS
    PORT(rst:   IN  std_logic;  -- reset,           RSTDEF active
         clk:   IN  std_logic;  -- clock,           rising edge
         en:    IN  std_logic;  -- enable,          high active
         inc:   IN  std_logic;  -- increment,       high active
         dec:   IN  std_logic;  -- decrement,       high active
         load:  IN  std_logic;  -- load value,      high active
         swrst: IN  std_logic;  -- software reset,  RSTDEF active
         cout:  OUT std_logic;  -- carry,           high active
         din:   IN  std_logic_vector(CNTLEN-1 DOWNTO 0);
         dout:  OUT std_logic_vector(CNTLEN-1 DOWNTO 0));
  END COMPONENT;

  SIGNAL rst:   std_logic := RSTDEF;
  SIGNAL clk:   std_logic := '0';
  SIGNAL hlt:   std_logic := '0';

  SIGNAL en:    std_logic := '0';
  SIGNAL inc:   std_logic := '0';
  SIGNAL dec:   std_logic := '0';
  SIGNAL load:  std_logic := '0';
  SIGNAL swrst: std_logic := '0';
  SIGNAL cout:  std_logic := '0';
  SIGNAL din:   std_logic_vector(CNTLEN-1 DOWNTO 0) := (OTHERS => '0');
  SIGNAL dout:  std_logic_vector(CNTLEN-1 DOWNTO 0) := (OTHERS => '0');
BEGIN
 rst <= RSTDEF, NOT RSTDEF AFTER 5*tpd;
 clk <= clk WHEN hlt='1' ELSE '1' AFTER tpd/2 WHEN clk='0' ELSE '0' AFTER tpd/2;

 stdc: std_counter
 PORT MAP(rst  => rst,
          clk  => clk,
          en => en,
          inc => inc,
          dec  => dec,
          load   => load,
          swrst  => swrst,
          cout   => cout,
          din => din,
          dout => dout);

  main: PROCESS

  PROCEDURE test1 IS
  BEGIN
    ASSERT FALSE REPORT "inc test..." SEVERITY note;
    WAIT UNTIL clk'EVENT AND clk='1' AND dout = "0000";
    inc <= '1';
    WAIT UNTIL clk'EVENT AND clk='1';
    inc <= '0';
    WAIT UNTIL clk'EVENT AND clk='1';
    ASSERT dout = "0000" REPORT "Did increase with enable 0" SEVERITY error;
    en <= '1';
    inc <= '1';
    WAIT UNTIL clk'EVENT AND clk='1';
    ASSERT dout = "0000" REPORT "Did increase on open" SEVERITY error;
    inc <= '0';
    WAIT UNTIL clk'EVENT AND clk='1';
    WAIT UNTIL clk'EVENT AND clk='1'; -- Frage: Normal das eine zweite Taktflanke gewartet werden muss
    ASSERT dout = "0001" REPORT "Didnt increase on close" SEVERITY error;
  END PROCEDURE;

  PROCEDURE test2 IS
  BEGIN
    ASSERT FALSE REPORT "dec test..." SEVERITY note;
    WAIT UNTIL clk'EVENT AND clk='1' AND dout = "0000";
    dec <= '1';
    WAIT UNTIL clk'EVENT AND clk='1';
    dec <= '0';
    WAIT UNTIL clk'EVENT AND clk='1';
    ASSERT dout = "0000" REPORT "Did decrease with enable 0" SEVERITY error;
    en <= '1';
    dec <= '1';
    WAIT UNTIL clk'EVENT AND clk='1';
    ASSERT dout = "0000" REPORT "Did decrease on open" SEVERITY error;
    dec <= '0';
    WAIT UNTIL clk'EVENT AND clk='1';
    WAIT UNTIL clk'EVENT AND clk='1'; -- Frage: Normal das eine zweite Taktflanke gewartet werden muss
    ASSERT dout = "1111" REPORT "Didnt decrease on close" SEVERITY error;
  END PROCEDURE;

  PROCEDURE test3 IS
  BEGIN
    ASSERT FALSE REPORT "load test..." SEVERITY note;
    din <= "0100";
    WAIT UNTIL clk'EVENT AND clk='1' AND dout = "0000";
    load <= '1';
    WAIT UNTIL clk'EVENT AND clk='1';
    load <= '0';
    WAIT UNTIL clk'EVENT AND clk='1';
    ASSERT dout = "0000" REPORT "Did load with enable 0" SEVERITY error;
    en <= '1';
    load <= '1';
    WAIT UNTIL clk'EVENT AND clk='1';
    WAIT UNTIL clk'EVENT AND clk='1'; -- Frage: Normal das eine zweite Taktflanke gewartet werden muss
    ASSERT dout = "0100" REPORT "Didnt load on open" SEVERITY error;
    load <= '0';
    WAIT UNTIL clk'EVENT AND clk='1';
    ASSERT dout = "0100" REPORT "Did load on close" SEVERITY error;
  END PROCEDURE;

  BEGIN
    WAIT UNTIL clk'EVENT AND clk='1' AND rst=(NOT RSTDEF);

    --test1;
    --test2;
    test3;

    ASSERT FALSE REPORT "done" SEVERITY note;

    hlt <= '1';
    WAIT;
  END PROCESS;
END test;
