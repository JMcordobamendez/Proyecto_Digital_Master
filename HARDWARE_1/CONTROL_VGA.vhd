library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--Controlador de escritura en la pantalla VGA
entity CONTROL_VGA is
    port(    CLK : in std_logic;
	         RESET : in std_logic;
			 HSYNC : out std_logic;
			 VSYNC : out std_logic;
			 CH_o : out std_logic_vector(9 downto 0);
			 CV_o : out std_logic_vector(9 downto 0));
end CONTROL_VGA;
architecture A1 of CONTROL_VGA is
    --Zonas de trabajo
    type tTimes is array (0 to 7) of integer;
    constant times : tTimes := (640,654,752,800,480,490,492,521); -- 640x480 (25 MHz) OK
    constant AH : integer := times(0); -- End Of Signal
    constant BH : integer := times(1); -- Start of Blanking
    constant CH : integer := times(2); -- End of Blanking
    constant DH : integer := times(3); -- End of Line
    constant AV : integer := times(4); -- End Of Signal
    constant BV : integer := times(5); -- Start of Blanking
    constant CV : integer := times(6); -- End of Blanking
    constant DV : integer := times(7); -- End of Line
	--Señales
	signal CONT_EN : std_logic; --Sincronizador
	signal DIVFREQ : unsigned(1 downto 0) := (others => '0');
	signal CH_i : unsigned(9 downto 0) := (others => '0');
	signal CV_i : unsigned(9 downto 0) := (others => '0');
begin
    --Divisor de frecuencia (100 MHz a 25 MHz)
	DIVF: process(CLK, RESET)
	begin
	    if(RESET = '1') then
		    DIVFREQ <= (others => '0');
		elsif rising_edge(CLK) then
		    DIVFREQ <= DIVFREQ + 1;
		end if;
	end process;
	CONT_EN <= '1' when std_logic_vector(DIVFREQ) = "11" else '0';
	--Contador del eje Horizontal
	CONT_H: process(CLK, RESET)
	begin
	    if (RESET = '1') then
		    CH_i <= (others => '0');
		elsif rising_edge(CLK) then
		    if (CONT_EN = '1') then
			    if (CH_i = DH) then
				    CH_i <= (others => '0');
				else
			        CH_i <= CH_i + 1;
				end if;
			end if;
		end if;
	end process;
	--Contador del eje Vertical
	CONT_V: process(CLK, RESET)
	begin
	    if (RESET = '1') then
		    CV_i <= (others => '0');
		elsif rising_edge(CLK) then
		    if (CONT_EN = '1') then
			    if (CH_i = DH) then
				    if (CV_i = DV) then
					    CV_i <= (others => '0');
					else
			            CV_i <= CV_i + 1;
					end if;
			    end if;
			end if;
		end if;
	end process;
	CH_o <= std_logic_vector(CH_i);
	CV_o <= std_logic_vector(CV_i);
	HSYNC <= '0' when ((CH_i >= BH) and (CH_i < CH)) else '1';
	VSYNC <= '0' when ((CV_i >= BV) and (CV_i < CV)) else '1';
end A1;