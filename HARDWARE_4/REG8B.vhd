library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--Here an 8 bits register is created to store the MAX/MIN values
entity REG8B is
    port(
	CLK : in std_logic;
	RESET : in std_logic;
	ENABLE : in std_logic;
	DATA : in std_logic_vector(7 downto 0);
	DATA_out : out std_logic_vector(7 downto 0));
end REG8B;
architecture A1 of REG8B is
    signal DATA_o : std_logic_vector(7 downto 0) := (others => '0');
begin
    REG: process(CLK, RESET)
	begin
	    if (RESET = '1') then
		    DATA_o <= (others => '0');
		else
		    if rising_edge(CLK) then
			    if (ENABLE = '1') then
				    DATA_o <= DATA;
				else
				    DATA_o <= DATA_o;
				end if;
			end if;
		end if;
	end process;
	DATA_out <= DATA_o;
end A1;
