LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity full_adder_N is
generic(N: natural := 8); -- generische Konstante
   port(cin: in std_logic;
      op1: in std_logic_vector(N-1 downto 0);
      op2: in std_logic_vector(N-1 downto 0);
      sum: out std_logic_vector(N-1 downto 0);
      cout: out std_logic
   );
end full_adder_N;

architecture structure of full_adder_N is
   component full_adder is
      port(cin: in std_logic; -- carry input
      op1: in std_logic; -- 1. operand
      op2: in std_logic; -- 2. operand
      sum: out std_logic; -- result
      cout: out std_logic); -- carry output
   end component;
   signal carry: std_logic_vector(N downto 0);
begin
   carry(0) <= cin;
   e1: for i in 0 to N-1 generate
      u1: full_adder
      port map(
         cin => carry(i),
         op1 => op1(i),
         op2 => op2(i),
         sum => sum(i),
         cout => carry(i+1));
   end generate;
   cout <= carry(N);
end structure;