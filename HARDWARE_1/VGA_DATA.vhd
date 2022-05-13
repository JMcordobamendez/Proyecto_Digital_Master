library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--Circuito combinacional (a ser posible, ya que si es muy largo requiere registros intermedios PIPELINE) que pinta los valores de la memoria RAM en el VGA
entity VGA_DATA is
    port(CLK : in std_logic;
	     DOUTB : in std_logic_vector(7 downto 0);
		 RESET : in std_logic;
		 CH : in std_logic_vector(9 downto 0);
		 CV : in std_logic_vector(9 downto 0);
		 ADDB : out std_logic_vector(9 downto 0);
		 ENB : out std_logic;
		 COLOR : out std_logic_vector(3 downto 0));
end VGA_DATA;
architecture A1 of VGA_DATA is
    --Valor que escala el dato para que aparezca en la mitad de la pantalla
	constant ESCALA : unsigned(8 downto 0) := "101101111"; --367
	--Cables intermedios (tener cuidado tal vez requiera de registros intermedios si no cumple criterio de tiempo)
	signal SOL : unsigned(8 downto 0);
	signal COLOR_i : std_logic_vector(3 downto 0);
begin
    --Realizar el escalado del valor para pintarlo en la pantalla
    SOL <= ESCALA - unsigned(DOUTB);
	--Si la posición vertical del VGA coincide con el valor escalado lo pintas
	COMB1: process(CH,CV,SOL)
	begin
	    if(unsigned(CH) < 640) then
		    if (unsigned(CV) = SOL) then
			    COLOR_i <= "1111";
			else
			    COLOR_i <= (others => '0');
			end if;
		else
		    COLOR_i <= (others => '0');
		end if;
	end process;
	--Si el valor vertical del VGA no se ha salido de la pantalla lo puedes pintar
	COMB2: process(COLOR_i, CV)
	begin
	    if (unsigned(CV) < 480) then
		    COLOR <= COLOR_i;
		else
		    COLOR <= (others => '0');
		end if;
	end process;
	--Conectar la dirección de la RAM con el contador horizontal si no se ha salido de la pantalla
	COMB3: process(CH)
	begin
	    if(unsigned(CH) < 640) then
		    ADDB <= CH;
		    ENB <= '1'; --Permite lectura
		else
		    ADDB <= (others => '0');
			ENB <= '0'; --No permitr lectura
		end if;
	end process;
end A1;

	
	
