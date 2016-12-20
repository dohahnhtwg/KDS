
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

ENTITY core IS
   GENERIC(RSTDEF: std_logic := '0');
   PORT(rst:   IN  std_logic;                      -- reset,          RSTDEF active
        clk:   IN  std_logic;                      -- clock,          rising edge
        swrst: IN  std_logic;                      -- software reset, RSTDEF active
        strt:  IN  std_logic;                      -- start,          high active
        sw:    IN  std_logic_vector( 7 DOWNTO 0);  -- length counter, input
        res:   OUT std_logic_vector(43 DOWNTO 0);  -- result
        done:  OUT std_logic);                     -- done,           high active
END core;

ARCHITECTURE structure OF core IS

   TYPE TState IS (S0, S1, S2, S3, S4, S5);        -- states control unit
   SIGNAL state: TState;
   
   SIGNAL n: unsigned( 7 DOWNTO 0);                -- Number of jobs
   SIGNAL en1: std_logic;                          -- Enable RAM Block
   SIGNAl en2: std_logic;                          -- Enable MULT18X18S
   SIGNAL en3: std_logic;                          -- Enable 44Bit-Adder

BEGIN

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
               END IF;
            WHEN S1 =>
               IF n = 0 THEN
                  state <= S5;
                  en1 <= '0';
                  en2 <= '0';
                  en3 <= '0';
               ELSE
                  n <= n - 1;
                  state <= S2;
                  en1 <= '1';
                  en2 <= '0';
                  en3 <= '0';
               END IF;
            WHEN S2 =>
               IF n = 0 THEN
                  state <= S4;
                  en1 <= '0';
                  en2 <= '1';
                  en3 <= '0';
               ELSE
                  n <= n - 1;
                  state <= S3;
                  en1 <= '1';
                  en2 <= '1';
                  en3 <= '0';
               END IF;
            WHEN S3 =>
               IF n = 0 THEN
                  state <= S4;
                  en1 <= '0';
                  en2 <= '1';
                  en3 <= '1';
               ELSE
                  n <= n - 1;
                  state <= S3;
                  en1 <= '1';
                  en2 <= '1';
                  en3 <= '1';
               END IF;
            WHEN S4 =>
               state <= S5;
               en1 <= '0';
               en2 <= '0';
               en3 <= '1';
            WHEN S5 =>
               state <= S0;
               en1 <= '0';
               en2 <= '0';
               en3 <= '0';
               done <= '1';
         END CASE;
      END IF;
   END PROCESS;

END structure;
