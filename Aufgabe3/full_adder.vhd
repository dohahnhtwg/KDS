LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity full_adder is
   port(cin: in std_logic; -- carry input
      op1: in std_logic; -- 1. operand
      op2: in std_logic; -- 2. operand
      sum: out std_logic; -- result
      cout: out std_logic -- carry output
   );
end full_adder;

architecture behavioral of full_adder is

   signal sel: std_logic_vector(1 to 3);
   signal tmp: std_logic_vector(1 to 2);
   
begin

   sel <= cin & op1 & op2;
   
   with sel select
   tmp <= "00" when "000",
      "01" when "001",
      "01" when "010",
      "10" when "011",
      "01" when "100",
      "10" when "101",
      "10" when "110",
      "11" when "111",
      "--" when others;
      
   sum <= tmp(2);
   cout <= tmp(1);
end behavioral;