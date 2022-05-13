library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity CONTROL_UART is
    port( READY : in std_logic;
	      RESET : in std_logic;
		    CLK : in std_logic;
		   DATA : in std_logic_vector(7 downto 0);
		   ADDA : out std_logic_vector(9 downto 0);
		    ENA_1 : out std_logic;
			ENA_2 : out std_logic);
end CONTROL_UART;
architecture A1 of CONTROL_UART is
    --Estado
    type StateType is (WAIT_1, CH1_E_a, CH1_E_b, CH1_E_c, WRITE_CH1a, WRITE_CH1b, WRITE_CH1c, CH2_E_a, CH2_E_b, CH2_E_c, WRITE_CH2a, WRITE_CH2b, WRITE_CH2c);
	--Signals
	signal C1 : unsigned(9 downto 0); --Contador de la dirección canal 1
	signal C1_DO : std_logic; --Enable contador
	signal C1_RESET : std_logic;
	signal SEL : std_logic;
	signal ENA : std_logic;
	--signal DATA_r : std_logic_vector(7 downto 0);
	--signal DATA_r_ena : std_logic;
	signal ADDA_EN : std_logic;
	signal STATE : StateType; 
	signal STATE_FORWARD : StateType := WAIT_1; --Inicializa el estado en WAIT_1
	
begin
    --Maquina Estados Sincroniza (circuito secuencial)
    --SINCR: process(CLK)
	SINCR: process(RESET, CLK)
	begin
		    if (RESET = '1') then
			    STATE <= WAIT_1;
				--STATE_FORWARD <= WAIT_1;
			elsif rising_edge(CLK) then
			    STATE <= STATE_FORWARD;
			end if;
		--end if;
	end process;
	--Maquina Estados Decoder Estado (circuito combibacional)
	DECSTATE: process(STATE, READY, DATA, C1)
	begin
	    C1_DO <= '0';
	    C1_RESET <= '0';
		ADDA_EN <= '0';
		ENA <= '0';
	    case STATE is
		    when WAIT_1 =>
			   -- if (RESET = '0') then
				    --if rising_edge(CLK) then
			            if (READY = '1') then
				            if (unsigned(DATA) = 49) then
					            STATE_FORWARD <= CH1_E_a;
					        elsif (unsigned(DATA) = 50) then
					            STATE_FORWARD <= CH2_E_a;
							else
							    STATE_FORWARD <= WAIT_1;
					        end if;
						else
						    STATE_FORWARD <= WAIT_1;
						end if;
				    --end if;
				--else
				  --  STATE_FORWARD <= WAIT_1;
				--end if;
				C1_RESET <= '1';
				SEL <= '0';
			
			when CH1_E_a =>
			    if (READY = '0') then
				    STATE_FORWARD <= CH1_E_b;
				else
				    STATE_FORWARD <= CH1_E_a;
				end if;
				SEL <= '0';
				
			when CH2_E_a =>
			    if (READY = '0') then
				    STATE_FORWARD <= CH2_E_b;
				else
				    STATE_FORWARD <= CH2_E_a;
				end if;
				SEL <= '1';
				
			when CH1_E_b =>
			    if (READY = '1') then
				    STATE_FORWARD <= CH1_E_c;
				else
				    STATE_FORWARD <= CH1_E_b;
				end if;
			    SEL <= '0';
				ADDA_EN <= '1';
				
			when CH2_E_b =>
			    if (READY = '1') then
				    STATE_FORWARD <= CH2_E_c;
				else
				    STATE_FORWARD <= CH2_E_b;
				end if;
			    SEL <= '1';
				ADDA_EN <= '1';
				
			when CH1_E_c =>
			    --if rising_edge(CLK) then
			        if (READY = '0') then
				        STATE_FORWARD <= WRITE_CH1a;
					else
					    STATE_FORWARD <= CH1_E_c;
					end if;
				--end if;
				ENA <= '1';
				SEL <= '0';
				
			when CH2_E_c =>
			    --if rising_edge(CLK) then
			        if (READY = '0') then
				        STATE_FORWARD <= WRITE_CH2a;
					else
					    STATE_FORWARD <= CH2_E_c;
				    end if;
				--end if;
				ENA <= '1';
				SEL <= '1';
				
			when WRITE_CH1a =>
			    --if rising_edge(CLK) then
				    --if (READY = '1') then
					    STATE_FORWARD <= WRITE_CH1c;
					--end if;
				--end if;
			    C1_DO <= '1';
				SEL <= '0';
				
			when WRITE_CH2a =>
			    --if rising_edge(CLK) then
				    --if (READY = '1') then
					    STATE_FORWARD <= WRITE_CH2c;
					--end if;
				--end if;
			    C1_DO <= '1';
				SEL <= '1';
				
			when WRITE_CH1c =>
			    --if rising_edge(CLK) then
				    STATE_FORWARD <= WRITE_CH1b;
				--end if;
			    SEL <= '0';
				
			when WRITE_CH2c =>
			    --if rising_edge(CLK) then
				    STATE_FORWARD <= WRITE_CH2b;
				--end if;
				SEL <= '1';
				
			when WRITE_CH1b =>
			    --if rising_edge(CLK) then
			        if (C1 < 640) then
				        STATE_FORWARD <= CH1_E_b;
				    else
				        STATE_FORWARD <= WAIT_1;
				    end if;
				--end if;
				SEL <= '0';
				
			when WRITE_CH2b =>
			    --if rising_edge(CLK) then
			        if (C1 < 640) then
				        STATE_FORWARD <= CH2_E_b;
				    else
				        STATE_FORWARD <= WAIT_1;
				    end if;
				--end if;
				SEL <= '1';
				
			when others =>
				STATE_FORWARD <= WAIT_1;
				SEL <= '1';
		end case;
	end process;
	
	CONT1: process(C1_RESET, CLK)
	begin
	    if (C1_RESET = '1') then
		    C1 <= (others => '0');
		elsif rising_edge(CLK) then
		    if (C1_DO = '1') then
		        C1 <= C1 + 1;
			end if;
		end if;
	end process;
	
	MUX: process(SEL, ENA)
	begin
	    if (SEL = '0') then
		    ENA_1 <= ENA;
			ENA_2 <= '0';
		else
		    ENA_1 <= '0';
			ENA_2 <= ENA;
		end if;
	end process;
	
	REG: process(CLK, RESET)
	begin
	    if (RESET = '1') then
		    ADDA <= (others => '0');
		elsif rising_edge(CLK) then
		    if (ADDA_EN = '1') then
			    ADDA <= std_logic_vector(C1);
			end if;
		end if;
	end process;
	
end A1;
