library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--Code to generate the modulated signal that will be the reference for the carrier signal (PWM)
entity MODULATOR_PHASE is
    port(
	    CLK : in std_logic;
		RESET : in std_logic;
		DATA : in std_logic_vector(7 downto 0);
		PHASE : in std_logic_vector(1 downto 0); --4 different phases can be selected [0, 90, 180, 270]
		ADDA : out std_logic_vector(9 downto 0);
		S : out std_logic_vector(3 downto 0);
		ENA : out std_logic);
end MODULATOR_PHASE;
architecture A1 of MODULATOR_PHASE is
    --Signals
	--Counter to control the position in the Look Up Table (ROM)
    signal C : unsigned(9 downto 0) := (others => '0');
	signal C_ENABLE : std_logic;
	signal C_CLEAR : std_logic;
	--Frequency divider
	--N_prescaler = (F_CLK)/(F_signal*N_signal_positions) => the minimun frequency of the signal is 1 KHz of 1 K values while the Clock frequency is 100 MHz
	signal F_DIV : unsigned(6 downto 0) := (others => '0');
	signal F_CLEAR : std_logic;
	--Selector of the mux
	--signal S : std_logic_vector(3 downto 0);
	signal M : unsigned(6 downto 0);
	signal P : unsigned(9 downto 0);
	--Phases
	constant P0 : unsigned(9 downto 0) := (others => '0');
	constant P90 : unsigned(9 downto 0) := "0011111001"; --249
	constant P180 : unsigned(9 downto 0) := "0111110011"; --499
	constant P270 : unsigned(9 downto 0) := "1011101101"; --749
	--constants selected to modulate the frequency
	constant F1 : unsigned(6 downto 0) := "1100100"; --100
	constant F2 : unsigned(6 downto 0) := "0110010"; --50
	constant F3 : unsigned(6 downto 0) := "0100001"; --33
	constant F4 : unsigned(6 downto 0) := "0011001"; --25
	constant F5 : unsigned(6 downto 0) := "0010100"; --20
	constant F6 : unsigned(6 downto 0) := "0010000"; --16
	constant F7 : unsigned(6 downto 0) := "0001110"; --14
	constant F8 : unsigned(6 downto 0) := "0001100"; --12
	constant F9 : unsigned(6 downto 0) := "0001011"; --11
	constant F10 : unsigned(6 downto 0) := "0001010"; --10
	
begin
    --UART decoder (combinational circuit)
	DECODER: process(DATA)
	begin
	    case DATA is
	        when "00110001" =>
		        S <= "0001";
			    M <= F1;
		    when "00110010" =>
		        S <= "0010";
			    M <= F2;
		    when "00110011" =>
		        S <= "0011";
			    M <= F3;
		    when "00110100" =>
		        S <= "0100";
			    M <= F4;
		    when "00110101" =>
		        S <= "0101";
			    M <= F5;
		    when "00110110" =>
		        S <= "0110";
			    M <= F6;
		    when "00110111" =>
		        S <= "0111";
			    M <= F7;
		    when "00111000" =>
		        S <= "1000";
			    M <= F8;
		    when "00111001" =>
		        S <= "1001";
			    M <= F9;
		    when "00110000" =>
		        S <= "1010";
			    M <= F10;
		    when others =>
		        S <= "1111";
			    M <= F1;
	    end case;
	end process;
	--Phase selector (it is a MUX)
	with PHASE select
	    P <= P0 when "00",
		     P90 when "01",
			 P180 when "10",
			 P270 when others;
	--Counter of the frequency divider
	FREQ_DIVIDER: process(CLK, RESET)
	begin
	    if (RESET = '1') then --Asynchronous RESET (Mux at the output of the register)
		    F_DIV <= (others => '0');
		else
		    if rising_edge(CLK) then
			    if (F_CLEAR = '0') then --Synchronous RESET (MUX at the input of the register)
				    F_DIV <= F_DIV + 1;
				else
				    F_DIV <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	--Combinational circuit of the frequency divider
	F_CLEAR <= '1' when (F_DIV >= (M - 1)) else '0';
	C_ENABLE <= F_CLEAR; --when the frequency divider reset it means that the position in the LUT must increase
	--Counter of the LUT position
	LUT_COUNTER: process(CLK, RESET, P)
	begin
	    if (RESET = '1') then
		    C <= P; --When the circuit restart it begins with a different phase
		else
		    if rising_edge(CLK) then
			    if (C_CLEAR = '0') then
				    if (C_ENABLE = '1') then --A second MUX in the input of the register
					    C <= C + 1;
					else
					    C <= C;
					end if;
				else
				    C <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	--Combinational circuit at the exit of the LUT Address counter
	C_CLEAR <= '1' when (C = 999) and (F_CLEAR = '1') else '0';
	ADDA <= std_logic_vector(C);
	ENA <= '1' when RESET = '0' else '0';

end A1;