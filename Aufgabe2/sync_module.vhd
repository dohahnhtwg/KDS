
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY sync_module IS
   GENERIC(RSTDEF: std_logic := '1');
   PORT(rst:   IN  std_logic;  -- reset, active RSTDEF
        clk:   IN  std_logic;  -- clock, risign edge
        swrst: IN  std_logic;  -- software reset, active RSTDEF
        BTN0:  IN  std_logic;  -- push button -> load
        BTN1:  IN  std_logic;  -- push button -> dec
        BTN2:  IN  std_logic;  -- push button -> inc
        load:  OUT std_logic;  -- load,      high active
        dec:   OUT std_logic;  -- decrement, high active
        inc:   OUT std_logic); -- increment, high active
END sync_module;

--
-- Im Rahmen der 2. Aufgabe soll hier die Architekturbeschreibung
-- zur Entity sync_module implementiert werden.
--
ARCHITECTURE behavioral OF sync_module IS
  COMPONENT sync_buffer IS
    GENERIC(RSTDEF:  std_logic);
    PORT(rst:    IN  std_logic;  -- reset, RSTDEF active
         clk:    IN  std_logic;  -- clock, rising edge
         en:     IN  std_logic;  -- enable, high active
         swrst:  IN  std_logic;  -- software reset, RSTDEF active
         din:    IN  std_logic;  -- data bit, input
         dout:   OUT std_logic;  -- data bit, output
         redge:  OUT std_logic;  -- rising  edge on din detected
         fedge:  OUT std_logic); -- falling edge on din detected
  END COMPONENT;
  
  constant CLOCK_DIVIDER_N: natural := 2**8; 							                                 -- mod-N for clock divider
  constant CLOCK_DIVIDER_N_BITS: integer := 8; 							                             -- mod-N for clock divider
  
  signal clock_divider_counter: std_logic_vector (CLOCK_DIVIDER_N_BITS-1 downto 0) := (others => '0');   -- counter of clock divider
  signal clock_divider_out: std_logic;                                                                   -- clock divider output (rising edge)
BEGIN

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

  -- sync_buffer load
  sb1: sync_buffer
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst   => rst,
             clk   => clk,
             en    => clock_divider_out,
             swrst => swrst,
             din   => BTN0,
			    dout  => open,
			    redge => load,
             fedge => open);
             
  -- sync_buffer dec
  sb2: sync_buffer
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst   => rst,
             clk   => clk,
             en    => clock_divider_out,
             swrst => swrst,
             din   => BTN1,
			    dout  => open,
             redge => open,
             fedge => dec);
  
  -- sync_buffer inc
  sb3: sync_buffer
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst   => rst,
             clk   => clk,
             en    => clock_divider_out,
             swrst => swrst,
             din   => BTN2,
			    dout  => open,
             redge => open,
             fedge => inc);
END behavioral;