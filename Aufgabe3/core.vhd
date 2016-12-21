LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;

LIBRARY unisim;
USE unisim.vcomponents.all;

ENTITY core IS
  GENERIC(RSTDEF: std_logic := '1');
  PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
       clk:   IN  std_logic;                      -- clock,          rising edge
       swrst: IN  std_logic;                      -- software reset, RSTDEF active
       strt:  IN  std_logic;                      -- start,          high active
       sw:    IN  std_logic_vector( 7 DOWNTO 0);  -- length counter, input
       res:   OUT std_logic_vector(43 DOWNTO 0);  -- result
       done:  OUT std_logic);                     -- done,           high active
END core;

ARCHITECTURE structure OF core IS

  -- U1
  COMPONENT ram_block IS
    PORT (addra: IN  std_logic_vector(9 DOWNTO 0);
          addrb: IN  std_logic_vector(9 DOWNTO 0);
          clka:  IN  std_logic;
          clkb:  IN  std_logic;
          douta: OUT std_logic_vector(15 DOWNTO 0);
          doutb: OUT std_logic_vector(15 DOWNTO 0);
          ena:   IN  std_logic;
          enb:   IN  std_logic);
  END COMPONENT;
  
  -- U2
  COMPONENT MULT18X18S IS
    PORT (p:  OUT std_logic_vector(35 DOWNTO 0);
          a:  IN  std_logic_vector(17 DOWNTO 0);
          b:  IN  std_logic_vector(17 DOWNTO 0);
          c:  IN  std_logic;
          ce: IN  std_logic;
          r:  IN  std_logic);
  END COMPONENT;
  
  -- U3
  COMPONENT adder_acc IS
    PORT (p:   OUT std_logic_vector(43 DOWNTO 0);
          a:   IN  std_logic_vector(35 DOWNTO 0);
          en:  IN  std_logic;
          rst: IN  std_logic;
          clk: IN  std_logic);
  END COMPONENT;

  -- Control Unit
  TYPE TState IS (S0, S1, S2, S3, S4, S5);        -- states control unit
  SIGNAL state: TState;
   
  SIGNAL n: unsigned( 7 DOWNTO 0);                -- Number of jobs
  SIGNAL en1: std_logic;                          -- Enable RAM Block
  SIGNAl en2: std_logic;                          -- Enable MULT18X18S
  SIGNAL en3: std_logic;                          -- Enable 44Bit-Adder
  
  -- U1 - Counter for Vector Addresses
  CONSTANT MEM_COUNTER_N: natural := 255;         -- Number of addresses per vector
  CONSTANT MEM_COUNTER_BITS: natural := 10;       -- Number of bits for MEM_COUNTER_N
  CONSTANT START_VEC_B: natural := 256;           -- First address of vector B
  SIGNAL mem_counter_vecA: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector A
  SIGNAL mem_counter_vecB: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector B
  
  -- U1 - Ram-Block
  SIGNAL vecA: std_logic_vector(15 DOWNTO 0);     -- Ram output of vector A
  SIGNAL vecB: std_logic_vector(15 DOWNTO 0);     -- Ram output of vector B
  
  -- U2 - Multiplicator
  SIGNAL vecA_se: std_logic_vector(17 DOWNTO 0);  -- Vector A after sign extension
  SIGNAL vecB_se: std_logic_vector(17 DOWNTO 0);  -- Vector B after sign extension
  SIGNAL u2_res: std_logic_vector(35 DOWNTO 0);   -- Result of multiplication
  
  -- U3 - Accumulator
  SIGNAL u3_res: std_logic_vector(43 DOWNTO 0);   -- Result of Accumulator
  
  -- Common
  SIGNAL intern_rst: std_logic;                   -- Reset uses in init
  SIGNAL global_rst: std_logic;                   -- Reset signal for component 1 and 2
BEGIN

  global_rst <= rst OR intern_rst;
  res <= u3_res;

  -- Control Unit
  PROCESS(rst, clk) IS
  BEGIN
    IF rst=RSTDEF THEN
      state <= S0;
      n <= to_unsigned(0, n'length);
      en1 <= '0';
      en2 <= '0';
      en3 <= '0';
      done <= '0';
      intern_rst <= '1';
    ELSIF rising_edge(clk) THEN
      CASE state IS
        WHEN S0 =>
          IF strt = '1' THEN
            n <= unsigned(sw);
            state <= S1;
            en1 <= '0';
            en2 <= '0';
            en3 <= '0';
            done <= '0';
            intern_rst <= '1';
          END IF;
        WHEN S1 =>
          IF n = 0 THEN
            state <= S5;
            en1 <= '0';
            en2 <= '0';
            en3 <= '0';
            intern_rst <= '0';
          ELSE
            n <= n - 1;
            state <= S2;
            en1 <= '1';
            en2 <= '0';
            en3 <= '0';
            intern_rst <= '0';
          END IF;
        WHEN S2 =>
          IF n = 0 THEN
            state <= S4;
            en1 <= '0';
            en2 <= '1';
            en3 <= '0';
            intern_rst <= '0';
          ELSE
            n <= n - 1;
            state <= S3;
            en1 <= '1';
            en2 <= '1';
            en3 <= '0';
            intern_rst <= '0';
          END IF;
        WHEN S3 =>
          IF n = 0 THEN
            state <= S4;
            en1 <= '0';
            en2 <= '1';
            en3 <= '1';
            intern_rst <= '0';
          ELSE
            n <= n - 1;
            state <= S3;
            en1 <= '1';
            en2 <= '1';
            en3 <= '1';
            intern_rst <= '0';
          END IF;
        WHEN S4 =>
          state <= S5;
          en1 <= '0';
          en2 <= '0';
          en3 <= '1';
          intern_rst <= '0';
        WHEN S5 =>
          state <= S0;
          en1 <= '0';
          en2 <= '0';
          en3 <= '0';
          done <= '1';
          intern_rst <= '0';
      END CASE;
    END IF;
  END PROCESS;
  
  -- Unit1 - Counter for Vector Addresses
  mem_counter_vecB <= mem_counter_vecA + START_VEC_B;
  PROCESS (global_rst, clk) BEGIN
    IF global_rst=RSTDEF THEN
      mem_counter_vecA <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF en1 = '1' THEN
        IF mem_counter_vecA = MEM_COUNTER_N THEN         -- TODO: Check if it is better to extend mem_counter_vecA
          mem_counter_vecA <= (OTHERS => '0');
        ELSE
          mem_counter_vecA <= mem_counter_vecA + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  -- Unit1 - Ram-Block
  u1: ram_block
  PORT MAP(addra => std_logic_vector(mem_counter_vecA),
           addrb => std_logic_vector(mem_counter_vecB),
           clka  => clk,
           clkb  => clk,
           douta => vecA,
           doutb => vecB,
           ena   => en1,
           enb   => en1);
           
  -- Unit2 - Multiplication
  vecA_se <= std_logic_vector(resize(signed(vecA), 18));
  vecB_se <= std_logic_vector(resize(signed(vecB), 18));
  u2: MULT18X18S
  PORT MAP(p  => u2_res,
           a  => vecA_se,
           b  => vecB_se,
           c  => clk,
           ce => en2,
           r  => global_rst);
           
  -- Unit3 - Adder
  u3: adder_acc
  PORT MAP(p   => u3_res,
           a   => u2_res,
           en  => en3,
           rst => global_rst,
           clk => clk);
  
END structure;
