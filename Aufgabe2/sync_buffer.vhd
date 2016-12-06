
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

ENTITY sync_buffer IS
  GENERIC(RSTDEF:  std_logic := '1');
  PORT(rst:    IN  std_logic;  -- reset, RSTDEF active
       clk:    IN  std_logic;  -- clock, rising edge
       en:     IN  std_logic;  -- enable, high active
       swrst:  IN  std_logic;  -- software reset, RSTDEF active
       din:    IN  std_logic;  -- data bit, input
       dout:   OUT std_logic;  -- data bit, output
       redge:  OUT std_logic;  -- rising  edge on din detected
       fedge:  OUT std_logic); -- falling edge on din detected
END sync_buffer;

--
-- Im Rahmen der 2. Aufgabe soll hier die Architekturbeschreibung
-- zur Entity sync_buffer implementiert werden.
--
ARCHITECTURE behavioral OF sync_buffer IS
  constant CNT_SIZE: natural := 2**5;                                                 -- sample size = 32
  constant CNT_BITS: integer := 5;

  COMPONENT flip_flop
    GENERIC(RSTDEF:  std_logic);
    PORT(rst:    IN  std_logic;  -- reset, RSTDEF active
         clk:    IN  std_logic;  -- clock, rising edge
         din:    IN  std_logic;  -- data bit, input
         dout:   OUT std_logic); -- data bit, output
  END COMPONENT;
  
  signal ff1_out:  std_logic;                                                        -- dff1 q
  signal ff2_out:  std_logic;                                                        -- dff2 q
  signal ff3_out:  std_logic;                                                        -- dff2 q+1
  
  type TState IS (S0, S1);                                                           -- states hysterese
  signal state: TState;
  signal cnt: std_logic_vector (CNT_BITS-1 downto 0);                                -- hysterese counter
  signal hyst_out: std_logic;                                                         -- hysterese out
begin

  -- dff1 Process
  ff1: flip_flop
  GENERIC MAP(RSTDEF => RSTDEF)
  PORT MAP(rst => rst,
           clk => clk,
           din => din,
           dout => ff1_out);
   
  -- dff2 Process
  ff2: flip_flop
  GENERIC MAP(RSTDEF => RSTDEF)
  PORT MAP(rst => rst,
           clk => clk,
           din => ff1_out,
           dout => ff2_out);
  
  -- hysterese
  process(rst, clk) is
  begin
    if rst=RSTDEF then
      state <= S0;
      cnt <= (others => '0');
      hyst_out <= '0';
    elsif rising_edge(clk) then
      if en = '1' then
        case state is
          when S0 =>
            if (ff2_out = '0') and (cnt = 0) then
              state <= S0;
              cnt <= cnt;
              hyst_out <= '0';
            elsif (ff2_out = '0') and (cnt > 0) then
              state <= S0;
              cnt <= cnt - 1;
              hyst_out <= '0';
            elsif (ff2_out = '1') and (cnt < CNT_SIZE-1) then
              state <= S0;
              cnt <= cnt + 1;
              hyst_out <= '0';
            elsif (ff2_out = '1') and (cnt = CNT_SIZE-1) then
              state <= S1;
              cnt <= cnt;
              hyst_out <= '0';
            end if;
          when S1 =>
            if (ff2_out = '1') and (cnt = CNT_SIZE-1) then
              state <= S1;
              cnt <= cnt;
              hyst_out <= '1';
            elsif (ff2_out = '1') and (cnt < CNT_SIZE-1) then
              state <= S1;
              cnt <= cnt + 1;
              hyst_out <= '1';
            elsif (ff2_out = '0') and (cnt > 0) then
              state <= S1;
              cnt <= cnt - 1;
              hyst_out <= '1';
            elsif (ff2_out = '0') and (cnt = 0) then
              state <= S0;
              cnt <= cnt;
              hyst_out <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;
   
  -- dff3 Process--
  ff3: flip_flop
  GENERIC MAP(RSTDEF => RSTDEF)
  PORT MAP(rst => rst,
           clk => clk,
           din => hyst_out,
           dout => ff3_out);
  
  -- output logic
  dout <= ff3_out;
  fedge <= ff3_out and not hyst_out;
  redge <= not ff3_out and hyst_out;
  
end behavioral;