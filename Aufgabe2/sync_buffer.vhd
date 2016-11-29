
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

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
architecture behavioral of sync_buffer is
  constant CLOCK_DIVIDER_N: natural := 2**15; 							                          -- mod-N for clock divider
  constant CLOCK_DIVIDER_N_BITS: integer := 15; 							                        -- mod-N for clock divider

  constant CNT_SIZE: natural := 2**5;                                                 -- sample size = 32
  constant CNT_BITS: integer := 5;

  signal dff1:  std_logic;                                                            -- dff1 q+1
  signal dff1_out:  std_logic;                                                        -- dff1 q
  signal dff2:  std_logic;                                                            -- dff2 q+1
  signal dff2_out:  std_logic;                                                        -- dff2 q
  signal dff3:  std_logic;                                                            -- dff2 q+1

  signal clock_divider_counter: std_logic_vector (CLOCK_DIVIDER_N_BITS-1 downto 0);   -- output of Modulo-4-Counter
  signal clock_divider_out: std_logic;                                                -- clock divider output (rising edge)
  
  type TState IS (S0, S1);                                                            -- states hysterese
  signal state: TState;
  signal cnt: std_logic_vector (CNT_BITS-1 downto 0);                                 -- hysterese counter
  signal hyst_out: std_logic;                                                         -- hysterese out
begin

  -- dff1 Process
  dff1_out <= dff1;

  process (rst, clk) is
  begin
     if rst=RSTDEF then
        dff1 <= '0';
     elsif rising_edge(clk) then
        dff1 <= din;
     end if;
  end process;
   
  -- dff2 Process
  dff2_out <= dff2;

  process (rst, clk) is
  begin
     if rst=RSTDEF then
        dff2 <= '0';
     elsif rising_edge(clk) then
        dff2 <= dff1;
     end if;
  end process;
  
  -- Modulo-2**15-Zaehler als Prozess
  process (rst, clk) begin
    if rst=RSTDEF then
      clock_divider_counter <= (others => '0');
      clock_divider_out <= '0';
    elsif rising_edge(clk) then
      clock_divider_out <= '0';
      if clock_divider_counter = CLOCK_DIVIDER_N - 1 then
        clock_divider_out <= '1';
      end if;
      clock_divider_counter <= clock_divider_counter + 1;
    end if;
  end process;
  
  -- hysterese
  process(rst, clk) is
  begin
    if rst=RSTDEF then
      state <= S0;
      cnt <= (others => '0');
    elsif rising_edge(clk) then
      if clock_divider_out = '1' then
        case state is
          when S0 =>
            if (dff2_out = '0') and (cnt = 0) then
              state <= S0;
              cnt <= cnt;
              hyst_out <= '0';
            elsif (dff2_out = '0') and (cnt > 0) then
              state <= S0;
              cnt <= cnt - 1;
              hyst_out <= '0';
            elsif (dff2_out = '1') and (cnt < CNT_SIZE-1) then
              state <= S0;
              cnt <= cnt + 1;
              hyst_out <= '0';
            elsif (dff2_out = '1') and (cnt < CNT_SIZE-1) then
              state <= S1;
              cnt <= cnt;
              hyst_out <= '0';
            end if;
          when S1 =>
            if (dff2_out = '1') and (cnt = CNT_SIZE-1) then
              state <= S1;
              cnt <= cnt;
              hyst_out <= '1';
            elsif (dff2_out = '1') and (cnt < CNT_SIZE-1) then
              state <= S1;
              cnt <= cnt + 1;
              hyst_out <= '1';
            elsif (dff2_out = '0') and (cnt > 0) then
              state <= S1;
              cnt <= cnt - 1;
              hyst_out <= '1';
            elsif (dff2_out = '0') and (cnt = 0) then
              state <= S0;
              cnt <= cnt;
              hyst_out <= '1';
            end if;
        end case;
      end if;
    end if;
  end process;
   
  -- dff3 Process
  process (rst, clk) is
  begin
     if rst=RSTDEF then
        dff3 <= '0';
     elsif rising_edge(clk) then
        dff3 <= hyst_out;
     end if;
  end process;
  
  -- output logic
  dout <= dff3;
  redge <= dff3 and not hyst_out;
  fedge <= not dff3 and hyst_out;
  
end behavioral;