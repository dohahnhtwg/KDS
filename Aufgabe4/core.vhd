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
    PORT (p:    OUT std_logic_vector(43 DOWNTO 0);
          addr: OUT std_logic_vector(9 downto 0);
          a:    IN  std_logic_vector(35 DOWNTO 0);
          en:   IN  std_logic;
          rst:  IN  std_logic;
          clk:  IN  std_logic);
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
  TYPE TState IS (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9);        -- states control unit
  SIGNAL state: TState;
   
  SIGNAL j: unsigned( 12 DOWNTO 0);                               -- Number of jobs
  CONSTANT NUMBER_JOBS: unsigned := to_unsigned(4096, j'length);  -- 16x16x16
  SIGNAL ens: std_logic_vector(4 DOWNTO 0);
  
  -- U1 - Addressgenerator
  CONSTANT N: unsigned(4 downto 0) := "10000";                     -- matrix size NxN
  CONSTANT MEM_COUNTER_BITS: natural := 10;                       -- Number of bits for MEM_COUNTER_N
  CONSTANT START_VEC_B: unsigned(8 downto 0) := "100000000";      -- First address of vector B
  SIGNAL mem_counter_vecA: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector A
  SIGNAL mem_counter_vecB: unsigned(MEM_COUNTER_BITS-1 downto 0); -- Actual adress of vector B
  
  -- U2 - ROM-Block
  SIGNAL vecA: std_logic_vector(15 DOWNTO 0);                     -- Rom output of vector A
  SIGNAL vecB: std_logic_vector(15 DOWNTO 0);                     -- Rom output of vector B
  
  -- U3 - Multiplicator
  SIGNAL vecA_se: std_logic_vector(17 DOWNTO 0);                  -- Vector A after sign extension
  SIGNAL vecB_se: std_logic_vector(17 DOWNTO 0);                  -- Vector B after sign extension
  SIGNAL u3_res: std_logic_vector(35 DOWNTO 0);                   -- Result of multiplication
  
  -- U4 - Accumulator
  SIGNAL u4_res: std_logic_vector(43 DOWNTO 0);                   -- Result of Accumulator
  SIGNAL mem_res: std_logic_vector(MEM_COUNTER_BITS-1 downto 0);  -- Actual adress of result
  
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
      ens <= "00000";
      rdy <= '0';
      intern_rst <= '1';
    ELSIF rising_edge(clk) THEN
      CASE state IS
        WHEN S0 =>
          IF strt = '1' THEN
            j <= NUMBER_JOBS;
            state <= S1;
            ens <= "00000";
            rdy <= '0';
            intern_rst <= '1';
          END IF;
        WHEN S1 =>
            j <= j - 1;
            state <= S2;
            ens <= "00001";
            intern_rst <= '0';
        WHEN S2 =>
            j <= j - 1;
            state <= S3;
            ens <= "00011";
            intern_rst <= '0';
        WHEN S3 =>
            j <= j - 1;
            state <= S4;
            ens <= "00111";
            intern_rst <= '0';
        WHEN S4 =>
            j <= j - 1;
            state <= S5;
            ens <= "01111";
            intern_rst <= '0';
        WHEN S5 =>
          IF j=0 THEN
            state <= S6;
            ens <= "11110";
            intern_rst <= '0';
          ELSE
            j <= j - 1;
            state <= S5;
            ens <= "11111";
            intern_rst <= '0';
          END IF;
        WHEN S6 =>
          state <= S7;
          ens <= "11100";
          intern_rst <= '0';
        WHEN S7 =>
          state <= S8;
          ens <= "11000";
          intern_rst <= '0';
        WHEN S8 =>
          state <= S9;
          ens <= "10000";
          intern_rst <= '0';
        WHEN S9 =>
          state <= S0;
          rdy <= '1';
          ens <= "00000";
          intern_rst <= '0';
      END CASE;
    END IF;
  END PROCESS;

  -- Unit1 - Addressgenerator
  PROCESS (global_rst, clk) 
    variable row: unsigned(3 downto 0);
    variable column: unsigned(3 downto 0);
    variable k: unsigned(3 downto 0);
  BEGIN
    IF global_rst=RSTDEF THEN
      mem_counter_vecA <= (OTHERS => '0');
      mem_counter_vecB <= (OTHERS => '0');
      row := (OTHERS => '0');
      column := (OTHERS => '0');
      k := (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      IF ens(0)='1' THEN
        mem_counter_vecA <= resize(row*N + k, mem_counter_vecA'length);
        mem_counter_vecB <= resize(column + k*N + START_VEC_B, mem_counter_vecB'length);
        IF k="1111" THEN
          IF column="1111" THEN
            row := row + 1;
          END IF;
          column := column + 1;
        END IF;
        k := k + 1;
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
           ena   => ens(1),
           enb   => ens(1));
           
  -- Unit3 - Multiplication
  vecA_se <= std_logic_vector(resize(signed(vecA), 18));
  vecB_se <= std_logic_vector(resize(signed(vecB), 18));
  u3: MULT18X18S
  PORT MAP(p  => u3_res,
           a  => vecA_se,
           b  => vecB_se,
           c  => clk,
           ce => ens(2),
           r  => global_rst);
           
  -- Unit4 - Adder
  u4: adder_acc
  PORT MAP(p    => u4_res,
           addr => mem_res,
           a    => u3_res,
           en   => ens(3),
           rst  => global_rst,
           clk  => clk);
           
  -- Unit5 - RamBlock
  mem_counter_vecRes <= resize(unsigned(sw), mem_counter_vecRes'length);
  dina <= std_logic_vector(resize(unsigned(u4_res), dina'length));
  u5: ram_block
  PORT MAP(addra => mem_res,
           addrb => std_logic_vector(mem_counter_vecRes),
           clka  => clk,
           clkb  => clk,
           dina  => dina,
           douta => OPEN,
           doutb => dout,
           ena   => ens(4),
           enb   => '1',
           wea   => ens(4));

END structure;