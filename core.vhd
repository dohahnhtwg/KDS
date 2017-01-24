LIBRARY ieee;
LIBRARY unisim;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
--USE ieee.std_logic_arith.all;
USE unisim.vcomponents.ALL;

ENTITY core IS
   GENERIC(RSTDEF: std_logic := '0');
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

ARCHITECTURE behavioral OF core IS
	--CONSTANT DIMENSION:    integer := 16;
	CONSTANT DIMENSION : std_logic_vector(3 DOWNTO 0) := "1111";
	
    COMPONENT rom_block IS
        PORT(addra: IN std_logic_vector(9 DOWNTO 0);
             addrb: IN std_logic_vector(9 DOWNTO 0);
             clka:  IN std_logic;
             clkb:  IN std_logic;
             douta: OUT std_logic_vector(15 DOWNTO 0);
             doutb: OUT std_logic_vector(15 DOWNTO 0);
             ena:   IN std_logic;
             enb:   IN std_logic);
    END COMPONENT;

    COMPONENT MULT18X18S IS
        PORT(R:     IN std_logic;
             C:     IN std_logic;
             CE:    IN std_logic;
             A:     IN  std_logic_vector(17 DOWNTO 0);
             B:     IN  std_logic_vector(17 DOWNTO 0);
             P:     OUT std_logic_vector(35 DOWNTO 0));
    END COMPONENT;

    COMPONENT accumulator IS
        GENERIC(RSTDEF:     std_logic);
        PORT(rst:   IN std_logic;
             clk:   IN std_logic;
             din:   IN std_logic_vector(35 DOWNTO 0);
             dout:  OUT std_logic_vector(43 DOWNTO 0));
    END COMPONENT;

    COMPONENT ram_block IS
        PORT(addra:   IN  std_logic_vector(9 DOWNTO 0);
             addrb:   IN  std_logic_vector(9 DOWNTO 0);
             clka:    IN  std_logic;
             clkb:    IN  std_logic;
             dina:    IN  std_logic_vector(15 DOWNTO 0);
             douta:   OUT std_logic_vector(15 DOWNTO 0);
             doutb:   OUT std_logic_vector(15 DOWNTO 0);
             ena:     IN  std_logic;
             enb:     IN  std_logic;
             wea:     IN  std_logic);
    END COMPONENT;

    -- Component signals
    SIGNAL rom_input_a:     std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rom_input_b:     std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rom_output_a:    std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rom_output_b:    std_logic_vector(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rom_enable:      std_logic := '0';

    SIGNAL mult_input_a:    std_logic_vector(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mult_input_b:    std_logic_vector(17 DOWNTO 0) := (OTHERS => '0');
    SIGNAL mult_output:     std_logic_vector(35 DOWNTO 0) := (OTHERS => '0');

    SIGNAL acc_enable:      std_logic := '0';
    SIGNAL acc_rst:         std_logic := '0';
    SIGNAL acc_manualrst:   std_logic := '0';
    SIGNAL acc_input:       std_logic_vector(35 DOWNTO 0) := (OTHERS => '0');
    SIGNAL acc_output:      std_logic_vector(43 DOWNTO 0) := (OTHERS => '0');

    SIGNAL ram_addr_a:      std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ram_addr_b:      std_logic_vector(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ram_wenable:     std_logic := '0';


    -- Stage control signals
    SIGNAL rom_enable_ROM:      std_logic := '0';
    SIGNAL acc_enable_ROM:      std_logic := '0';
    SIGNAL acc_manualrst_ROM:   std_logic := '0';
    SIGNAL ram_wenable_ROM:     std_logic := '0';
    SIGNAL rdy_ROM:             std_logic := '0';
    SIGNAL acc_enable_MUL:      std_logic := '0';
    SIGNAL acc_manualrst_MUL:   std_logic := '0';
    SIGNAL ram_wenable_MUL:     std_logic := '0';
    SIGNAL rdy_MUL:             std_logic := '0';
    SIGNAL ram_wenable_ACC:     std_logic := '0';
    SIGNAL rdy_ACC:             std_logic := '0';

    SIGNAL idle:                std_logic := '1';
    SIGNAL tmp:					std_logic := '0';

BEGIN
    u_romblock: rom_block
    PORT MAP(addra => rom_input_a,
             addrb => rom_input_b,
             clka => clk,
             clkb => clk,
             douta => rom_output_a,
             doutb => rom_output_b,
             ena => rom_enable,
             enb => rom_enable);

    u_MULT18X18: MULT18X18S
    PORT MAP(C  => clk,
             CE => '1',
             R  => rst,
             A  => mult_input_a,
             B  => mult_input_b,
             P  => mult_output);
    mult_input_a <= std_logic_vector(resize(signed(rom_output_a), mult_input_a'LENGTH));
    mult_input_b <= std_logic_vector(resize(signed(rom_output_b), mult_input_b'LENGTH));

    u_signedacc: accumulator
    GENERIC MAP(RSTDEF => RSTDEF)
    PORT MAP(rst => acc_rst,
             clk => clk,
             din => acc_input,
             dout => acc_output);
    acc_rst <= rst OR strt OR acc_manualrst OR swrst;
    acc_input <= mult_output WHEN acc_enable = '1' ELSE (OTHERS => '0');

    u_ramblock: ram_block
    PORT MAP(addra => ram_addr_a,
             addrb => ram_addr_b,
             clka => clk,
             clkb => clk,
             dina => acc_output(15 DOWNTO 0),
             douta => OPEN,
             doutb => dout,
             ena => '1',
             enb => '1',
             wea => ram_wenable);
    ram_addr_b <= "00" & sw;

    main: PROCESS(clk, rst)
        VARIABLE i : std_logic_vector(3 DOWNTO 0);
		VARIABLE j : std_logic_vector(3 DOWNTO 0);
		VARIABLE k : std_logic_vector(3 DOWNTO 0);
		
		VARIABLE addr_a : std_logic_vector(8 DOWNTO 0) := "000000000";
		VARIABLE addr_b : std_logic_vector(8 DOWNTO 0) := "100000000";
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = RSTDEF OR swrst = RSTDEF THEN
                rom_enable <= '0';
                acc_enable <= '0';
                ram_wenable <= '0';

                rom_enable_ROM <= '0';
                acc_enable_ROM <= '0';
                acc_manualrst_ROM <= '0';
                ram_wenable_ROM <= '0';
                rdy_ROM <= '0';
                acc_enable_MUL <= '0';
                acc_manualrst_MUL <= '0';
                ram_wenable_MUL <= '0';
                rdy_MUL <= '0';
                ram_wenable_ACC <= '0';
                rdy_ACC <= '0';
				tmp <= '0';
				
                idle <= '1';
                rdy <= '0';
				i := (OTHERS => '0');
				j := (OTHERS => '0');
				k := (OTHERS => '0');
            ELSE
                IF strt = '1' THEN
					i := (OTHERS => '0');
					j := (OTHERS => '0');
					k := (0 => '1', OTHERS => '0');
                    addr_a := "000000000";
                    addr_b := "100000000";

                    rom_enable <= '1';
					
					rom_input_a <= '0' & addr_a;
                    rom_input_b <= '0' & addr_b;
					
                    acc_enable <= '0';
                    ram_wenable <= '0';

                    rom_enable_ROM <= '1';
                    acc_enable_ROM <= '1';
                    acc_manualrst_ROM <= '0';
                    ram_wenable_ROM <= '0';
                    rdy_ROM <= '0';
                    acc_enable_MUL <= '0';
                    acc_manualrst_MUL <= '0';
                    ram_wenable_MUL <= '0';
                    rdy_MUL <= '0';
                    ram_wenable_ACC <= '0';
                    rdy_ACC <= '0';
					tmp <= '1';
                    rdy <= '0';
                    idle <= '0';
                ELSE
                	IF tmp = '1' THEN
	                    IF idle = '0' THEN
							--rst <= '0';
							-- @
	                        addr_a := '0' & i & k; 
	                        addr_b := '1' & k & j;
							
							rom_input_a <= '0' & addr_a;
							rom_input_b <= '0' & addr_b;
	                        IF k = DIMENSION THEN
	                            acc_manualrst_ROM <= '1';
	                            ram_wenable_ROM <= '1';
								ram_addr_a <= "00" & i & j;
							ELSE
	                            acc_manualrst_ROM <= '0';
	                            ram_wenable_ROM <= '0';
	                        END IF;
	
	                        IF k < DIMENSION THEN
	                            k := std_logic_vector( signed(k) + 1 );
	                        ELSE
	                            k := (OTHERS => '0');
	                            IF j < DIMENSION THEN 
	                                j := std_logic_vector( signed(j) + 1 );
	                            ELSE
	                                j := (OTHERS => '0');
	                          IF i < DIMENSION THEN 
									i := std_logic_vector( signed(i) + 1 ); 
	                                ELSE
	                                    -- Last element
	                                    rom_enable_ROM <= '0';
	                                    
	                                    idle <= '1';
	                                END IF;
	                            END IF;
	                        END IF;
	                    ELSE
							rdy_ROM <= '1';
	                        acc_enable_ROM <= '0';
	                        ram_wenable_ROM <= '0';
	                    END IF;
					END IF;
                    -- ROM
                    rom_enable <= rom_enable_ROM;
                    acc_enable_MUL <= acc_enable_ROM;
                    acc_enable <= acc_enable_ROM;
                    acc_manualrst_MUL <= acc_manualrst_ROM;
                    ram_wenable_MUL <= ram_wenable_ROM;
                    rdy_MUL <= rdy_ROM;

                    -- MUL
                    acc_enable <= acc_enable_MUL;
                    acc_manualrst <= acc_manualrst_MUL;
                    ram_wenable_ACC <= ram_wenable_MUL;
                    rdy_ACC <= rdy_MUL;

                    -- ACC
                    ram_wenable <= ram_wenable_ACC;
                    rdy <= rdy_ACC;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END behavioral;