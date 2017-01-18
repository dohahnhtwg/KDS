
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
        -- handshake signals
        strt:  IN  std_logic;                      -- start,          high active
        rdy:   OUT std_logic;                      -- ready,          high active
        -- address/data signals
        sw:    IN  std_logic_vector( 7 DOWNTO 0);  -- address input
        dout:  OUT std_logic_vector(15 DOWNTO 0)); -- result output
END core;

-- Erweiterung um die Architekturbeschreibung
ARCHITECTURE structure OF core IS

  -- U2
  COMPONENT rom_block IS
    PORT (addra: IN  std_logic_vector(9 DOWNTO 0);
          addrb: IN  std_logic_vector(9 DOWNTO 0);
          clka:  IN  std_logic;
          clkb:  IN  std_logic;
          douta: OUT std_logic_vector(15 DOWNTO 0);
          doutb: OUT std_logic_vector(15 DOWNTO 0);
          ena:   IN  std_logic;
          enb:   IN  std_logic);
  END COMPONENT;
  
  -- U3
  COMPONENT MULT18X18S IS
    PORT (p:  OUT std_logic_vector(35 DOWNTO 0);
          a:  IN  std_logic_vector(17 DOWNTO 0);
          b:  IN  std_logic_vector(17 DOWNTO 0);
          c:  IN  std_logic;
          ce: IN  std_logic;
          r:  IN  std_logic);
  END COMPONENT;
  
  -- U4
  COMPONENT adder_acc IS
    PORT (p:   OUT std_logic_vector(43 DOWNTO 0);
          a:   IN  std_logic_vector(35 DOWNTO 0);
          en:  IN  std_logic;
          rst: IN  std_logic;
          clk: IN  std_logic);
  END COMPONENT;
  
  -- U5
  COMPONENT ram_block IS
    PORT (addra: IN  std_logic_vector(9 DOWNTO 0);
          addrb: IN  std_logic_vector(9 DOWNTO 0);
          clka:  IN  std_logic;
          clkb:  IN  std_logic;
          dina:  IN  std_logic_VECTOR(15 downto 0);
          douta: OUT std_logic_vector(15 DOWNTO 0);
          doutb: OUT std_logic_vector(15 DOWNTO 0);
          ena:   IN  std_logic;
          enb:   IN  std_logic;
          wea:   IN  std_logic);
  END COMPONENT;

  -- Control Unit
  TYPE TState IS (S0, S1, S2, S3, S4, S5, S6, S7, S8);            -- states control unit
  SIGNAL state: TState;
   
  SIGNAL j: unsigned( 12 DOWNTO 0);                               -- Number of jobs
  CONSTANT NUMBER_JOBS: unsigned := to_unsigned(4096, j'length);  -- 16x16x16
  SIGNAL en1: std_logic;                                          -- Enable AddressGenerator
  SIGNAl en2: std_logic;                                          -- Rom-Block
  SIGNAL en3: std_logic;                                          -- Enable MULT18X18S
  SIGNAL en4: std_logic;                                          -- Enable 44Bit-Adder
  
  -- U1 - Addressgenerator
  CONSTANT N: natural := 16;                                      -- matrix size NxN
  CONSTANT MEM_COUNTER_BITS: natural := 10;                       -- Number of bits for MEM_COUNTER_N
  CONSTANT START_VEC_B: natural := 256;                           -- First address of vector B
  SIGNAL mem_counter_vecA: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector A
  SIGNAL mem_counter_vecB: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector B
  SIGNAL mem_counter_vecC: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector C
  
  -- U2 - ROM-Block
  SIGNAL vecA: std_logic_vector(15 DOWNTO 0);                     -- Rom output of vector A
  SIGNAL vecB: std_logic_vector(15 DOWNTO 0);                     -- Rom output of vector B
  
  -- U3 - Multiplicator
  SIGNAL vecA_se: std_logic_vector(17 DOWNTO 0);                  -- Vector A after sign extension
  SIGNAL vecB_se: std_logic_vector(17 DOWNTO 0);                  -- Vector B after sign extension
  SIGNAL u3_res: std_logic_vector(35 DOWNTO 0);                   -- Result of multiplication
  
  -- U4 - Accumulator
  SIGNAL u4_res: std_logic_vector(43 DOWNTO 0);                   -- Result of Accumulator
  
  -- U5 - RAM-Block
  SIGNAL mem_counter_vecRes: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector Result
  SIGNAL dina: std_logic_VECTOR(15 downto 0);                       -- input dina
  
  -- Common
  SIGNAL intern_rst: std_logic;                                   -- Reset uses in init
  SIGNAL global_rst: std_logic;                                   -- Reset signal for component 1 and 2
BEGIN

  global_rst <= rst OR intern_rst;

  -- Control Unit
  PROCESS(rst, clk) IS
  BEGIN
    IF rst=RSTDEF THEN
      state <= S0;
      j <= to_unsigned(0, j'length);
      en1 <= '0';
      en2 <= '0';
      en3 <= '0';
      en4 <= '0';
      rdy <= '0';
      intern_rst <= '1';
    ELSIF rising_edge(clk) THEN
      CASE state IS
        WHEN S0 =>
          IF strt = '1' THEN
            j <= NUMBER_JOBS;
            state <= S1;
            en1 <= '0';
            en2 <= '0';
            en3 <= '0';
            en4 <= '0';
            rdy <= '0';
            intern_rst <= '1';
          END IF;
        WHEN S1 =>
          IF j = 0 THEN
            state <= S7;
            en1 <= '0';
            en2 <= '0';
            en3 <= '0';
            en4 <= '0';
            intern_rst <= '0';
          ELSE
            j <= j - 1;
            state <= S2;
            en1 <= '1';
            en2 <= '0';
            en3 <= '0';
            en4 <= '0';
            intern_rst <= '0';
          END IF;
        WHEN S2 =>
          IF j = 0 THEN
            state <= S8;
            en1 <= '0';
            en2 <= '1';
            en3 <= '0';
            en4 <= '0';
            intern_rst <= '0';
          ELSE
            j <= j - 1;
            state <= S3;
            en1 <= '1';
            en2 <= '1';
            en3 <= '0';
            en4 <= '0';
            intern_rst <= '0';
          END IF;
        WHEN S3 =>
          IF j = 0 THEN
            state <= S5;
            en1 <= '0';
            en2 <= '1';
            en3 <= '1';
            en4 <= '0';
            intern_rst <= '0';
          ELSE
            j <= j - 1;
            state <= S4;
            en1 <= '1';
            en2 <= '1';
            en3 <= '1';
            en4 <= '0';
            intern_rst <= '0';
          END IF;
        WHEN S4 =>
          IF j = 0 THEN
            state <= S5;
            en1 <= '0';
            en2 <= '1';
            en3 <= '1';
            en4 <= '1';
            intern_rst <= '0';
          ELSE
            j <= j - 1;
            state <= S4;
            en1 <= '1';
            en2 <= '1';
            en3 <= '1';
            en4 <= '1';
            intern_rst <= '0';
          END IF;
        WHEN S5 =>
          state <= S6;
          en1 <= '0';
          en2 <= '0';
          en3 <= '1';
          en4 <= '1';
          intern_rst <= '0';
        WHEN S6 =>
          state <= S7;
          en1 <= '0';
          en2 <= '0';
          en3 <= '0';
          en3 <= '0';
          en4 <= '1';
          intern_rst <= '0';
        WHEN S7 =>
          state <= S0;
          en1 <= '0';
          en2 <= '0';
          en3 <= '0';
          en4 <= '0';
          rdy <= '1';
          intern_rst <= '0';
        WHEN S8 =>
          state <= S6;
          en1 <= '0';
          en2 <= '0';
          en3 <= '1';
          en4 <= '0';
          intern_rst <= '0';
      END CASE;
    END IF;
  END PROCESS;

  -- Unit1 - Addressgenerator
  PROCESS (global_rst, clk) 
    variable row: natural;
    variable column: natural;
    variable k: natural;
  BEGIN
    IF global_rst=RSTDEF THEN
      mem_counter_vecA <= (OTHERS => '0');
      mem_counter_vecB <= (OTHERS => '0');
      mem_counter_vecC <= (OTHERS => '0');
      row := 0;
      column := 0;
      k := 0;
    ELSIF rising_edge(clk) THEN
      IF en1='1' THEN
        IF row<N THEN
          IF column<N THEN
            IF k<N THEN
              mem_counter_vecA <= to_unsigned(row*N + k, mem_counter_vecA'length);
              mem_counter_vecB <= to_unsigned(column + k*N + START_VEC_B, mem_counter_vecB'length);
              k := k + 1;
            END IF;
            IF k=N THEN
              column := column + 1;
              k := 0;
              mem_counter_vecC <= mem_counter_vecC + 1;
            END IF;
          END IF;
          IF column=N THEN
            row := row + 1;
            column := 0;
          END IF;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
  -- Unit2 - Rom-Block
  u2: rom_block
  PORT MAP(addra => std_logic_vector(mem_counter_vecA),
           addrb => std_logic_vector(mem_counter_vecB),
           clka  => clk,
           clkb  => clk,
           douta => vecA,
           doutb => vecB,
           ena   => en2,
           enb   => en2);
           
  -- Unit3 - Multiplication
  vecA_se <= std_logic_vector(resize(signed(vecA), 18));
  vecB_se <= std_logic_vector(resize(signed(vecB), 18));
  u3: MULT18X18S
  PORT MAP(p  => u3_res,
           a  => vecA_se,
           b  => vecB_se,
           c  => clk,
           ce => en3,
           r  => global_rst);
           
  -- Unit4 - Adder
  u4: adder_acc
  PORT MAP(p   => u4_res,
           a   => u3_res,
           en  => en4,
           rst => global_rst,
           clk => clk);
           
  -- Unit5 - RamBlock
  mem_counter_vecRes <= resize(unsigned(sw), mem_counter_vecRes'length);
  dina <= std_logic_vector(resize(unsigned(u4_res), dina'length));
  u5: ram_block
  PORT MAP(addra => std_logic_vector(mem_counter_vecC),
           addrb => std_logic_vector(mem_counter_vecRes),
           clka  => clk,
           clkb  => clk,
           dina  => dina,
           douta => OPEN,
           doutb => dout,
           ena   => en4,
           enb   => en4,
           wea   => en4);

END structure;
