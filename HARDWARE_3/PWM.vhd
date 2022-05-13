library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity PWM is
    port(
	    CLK : in std_logic;
		RESET : in std_logic;
		REF : in std_logic_vector(9 downto 0);
		Y : out std_logic);
end PWM;
architecture A1 of PWM is
    signal C : unsigned(9 downto 0) := (others => '0');
	signal CLEAR : std_logic;
begin
    --Accumulator of 1 bit per clk rising edge
	--100M/1K = 100KHz PWM signal
    CONT: process(CLK, RESET)
	begin
	    if(RESET = '1') then
		    C <= (others => '0');
		else
		    if rising_edge(CLK) then
			    if (clear = '0') then
				    C <= C + 1;
				else
				    C <= (others => '0');
				end if;
			end if;
		end if;
	end process;
	--Combinational circuit
	--PWM signal
	Y <= '1' when (C < unsigned(REF)) else '0';
	--Synchronous reset to avoid glitches
	CLEAR <= '0' when (C < 999) else '1';
end A1;	