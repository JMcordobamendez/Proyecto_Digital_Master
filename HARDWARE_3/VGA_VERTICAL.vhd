library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--Combinational circuit that prints a vertical line in the middle of the screen
entity VGA_VERTICAL is
    port(
	    CH : in std_logic_vector(9 downto 0);
	    CV : in std_logic_vector(9 downto 0);
	    COLOR : out std_logic_vector(3 downto 0));
end VGA_VERTICAL;
architecture A1 of VGA_VERTICAL is
    signal COLOR_i : std_logic_vector(3 downto 0);
begin
    COMB1: process(CH,CV)
	begin
	    if (unsigned(CH) < 640) then
		    if (unsigned(CH) = ((640/2) - 1)) then
			    COLOR_i <= (others => '1');
			else
			    COLOR_i <= (others => '0');
			end if;
		else
		    COLOR_i <= (others => '0');
		end if;
	end process;
	COMB2: process(CV, COLOR_i)
	begin
	    if (unsigned(CV) < 480) then
		    COLOR <= COLOR_i;
		else
		    COLOR <= (others => '0');
		end if;
	end process;
end A1;