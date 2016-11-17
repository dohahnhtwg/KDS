
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
   signal dff1:  std_logic;            -- dff1 q+1
   signal dff1_out:  std_logic;        -- dff1 q
   signal dff2:  std_logic;            -- dff2 q+1
   signal dff2_out:  std_logic;        -- dff2 q
begin

   -- dff1 Process
   dff1_out <= dff1

   process (rst, clk) is
      begin
         if rst=RSTDEF then
            dff1 <= '0';
         elsif rising_edge(clk) then
            dff1 <= din;
         end if;
   end process;
   
   -- dff2 Process
   dff2_out <= dff2

   process (rst, clk) is
      begin
         if rst=RSTDEF then
            dff2 <= '0';
         elsif rising_edge(clk) then
            dff2 <= dff1;
         end if;
   end process;

end behavioral;