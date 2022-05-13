library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
entity DDS is
    port(
	    CLK : in std_logic;
		RESET : in std_logic;
		RX : in std_logic;
		S : out std_logic_vector(3 downto 0);
		Y : out std_logic);
end DDS;
architecture A1 of DDS is
    --Import components
    --Driver to read UART protocol
    component UART_RX is
    generic (
      BAUDRATE : INTEGER := 70000;     -- Desired baudrate 115200 
      CLK_FREQ : INTEGER := 100000000  -- Input clock in Hz
    );
    port (
      reset    : IN  STD_LOGIC;
      clk      : IN  STD_LOGIC;
      rx       : IN  STD_LOGIC;
      data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0 );
      ready    : OUT STD_LOGIC
    );
    end component;
	--Register of 8 bits
	component REG8B is
	port(
	         CLK : in std_logic;
	       RESET : in std_logic;
	      ENABLE : in std_logic;
	        DATA : in std_logic_vector(7 downto 0);
	    DATA_out : out std_logic_vector(7 downto 0));
	end component;
	--PWM (carrier signal)
	component PWM is
    port(
	    CLK : in std_logic;
		RESET : in std_logic;
		REF : in std_logic_vector(9 downto 0);
		Y : out std_logic);
    end component;
	--Modulator
	component MODULATOR is
    port(
	    CLK : in std_logic;
		RESET : in std_logic;
		--DOUTA : in std_logic_vector(9 downto 0);
		DATA : in std_logic_vector(7 downto 0);
		ADDA : out std_logic_vector(9 downto 0);
		S : out std_logic_vector(3 downto 0);
		ENA : out std_logic);
    end component;
	--ROM block where the LUT values are kept
	component blk_mem_rom IS
    PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
    end component;
	--Signals
    signal DATA_V : std_logic_vector(7 downto 0);
	signal DATA_F : std_logic_vector(7 downto 0);
	signal RESET_UART : std_logic;
	signal READY : std_logic;
	signal ADDA : std_logic_vector(9 downto 0);
	signal ENA : std_logic;
	signal REF : std_logic_vector(9 downto 0);
begin
    --The Asynchronous RESET of the UART is sensitive to '0' (the rest of the circuit to '1')
    RESET_UART <= not RESET;
    --Block of the UART driver
    UART_DRIVER_b: UART_RX port map(
	       reset => RESET_UART,
             clk => CLK,
		      rx => RX,
		data_out => DATA_V,
		   ready => READY);
	--Register to store the DATA from the driver
	REG8B_b: REG8B port map(
	        CLK => CLK,
	      RESET => RESET,
	     ENABLE => READY,
	       DATA => DATA_V,
	   DATA_out => DATA_F);
	--Block to produce the modulated signal
	MODULATOR_b: MODULATOR port map(
	        CLK => CLK,
		  RESET => RESET,
		   DATA => DATA_F,
		   ADDA => ADDA,
		      S => S,
		    ENA => ENA);
	--Block of the ROM where the values of the Look Up Table are stored (with these values a sinus is made)
    ROM_b: blk_mem_rom port map(
	     clka => CLK,
          ena => ENA,
        addra => ADDA,
        douta => REF);
	--Block of the PWM to produce the carrier signal and the modulation one inside
	PWM_b: PWM port map(
	      CLK => CLK,
		RESET => RESET,
		  REF => REF,
		    Y => Y);
end A1;
		