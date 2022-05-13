library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
--Prueba integración de todo el Hardware junto :)
entity HARDWARE_3 is
    port(     CLK : in std_logic;
	        RESET : in std_logic;
			   RX : in std_logic;
			 RX_S : in std_logic;
			    S : out std_logic_vector(3 downto 0);
				Y : out std_logic;
		    HSYNC : out std_logic;
		    VSYNC : out std_logic;
	      COLOR_R : out std_logic_vector(3 downto 0);
	      COLOR_G : out std_logic_vector(3 downto 0);
	      COLOR_B : out std_logic_vector(3 downto 0));
end HARDWARE_3;
architecture A1 of HARDWARE_3 is
    --Define the components
    --Data path of the VGA
    component VGA_DATA is
	    port(    CLK : in std_logic;
	           DOUTB : in std_logic_vector(7 downto 0);
		       RESET : in std_logic;
		          CH : in std_logic_vector(9 downto 0);
		          CV : in std_logic_vector(9 downto 0);
		        ADDB : out std_logic_vector(9 downto 0);
		         ENB : out std_logic;
		       COLOR : out std_logic_vector(3 downto 0));
	end component;
	--Synchronizer/Controller of VGA
	component CONTROL_VGA is
	    port(    CLK : in std_logic;
	           RESET : in std_logic;
			   HSYNC : out std_logic;
			   VSYNC : out std_logic;
			    CH_o : out std_logic_vector(9 downto 0);
			    CV_o : out std_logic_vector(9 downto 0));
	end component;
	--Driver to read UART protocol
    component UART_RX is
    generic (
      BAUDRATE : INTEGER := 115200;     -- Desired baudrate
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
    --Driver to store the data of the UART in the RAM and in the registers of MAX/MIN values
    component CONTROL_UART is
    port( READY : in std_logic;
	      RESET : in std_logic;
		    CLK : in std_logic;
		   DATA : in std_logic_vector(7 downto 0);
		   ADDA : out std_logic_vector(9 downto 0);
		  ENA_1 : out std_logic;
	      ENA_2 : out std_logic;
		ENA_MAX : out std_logic;
		ENA_MIN : out std_logic);
    end component;
	--IP (Intellectual Property) of the RAM
	component blk_mem_gen_0 is
    PORT (
        clka : IN STD_LOGIC;
         ena : IN STD_LOGIC;
         wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
       addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        clkb : IN STD_LOGIC;
         enb : IN STD_LOGIC;
       addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
       doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
    end component;
	--REG to store the MAX/MIN Values
	component REG8B is
	port(
	         CLK : in std_logic;
	       RESET : in std_logic;
	      ENABLE : in std_logic;
	        DATA : in std_logic_vector(7 downto 0);
	    DATA_out : out std_logic_vector(7 downto 0));
	end component;
	--Combinational circuit to print the vertical line in the screen
	component VGA_VERTICAL is
	    port(
	        CH : in std_logic_vector(9 downto 0);
	        CV : in std_logic_vector(9 downto 0);
	        COLOR : out std_logic_vector(3 downto 0));
	end component;
	----PWM (carrier signal)
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
	--Define the "wires" to join the components
	signal RESET_UART : std_logic;
	signal READY : std_logic;
	signal DATA, DATA_MAX, DATA_MIN : std_logic_vector(7 downto 0);
	signal ENA_1, ENA_2 : std_logic;
	signal ENB_1, ENB_2 : std_logic;
	signal ENA_MAX, ENA_MIN : std_logic;
	signal ADDA, ADDB_1, ADDB_2 : std_logic_vector(9 downto 0);
	signal DOUTB_1, DOUTB_2 : std_logic_vector(7 downto 0);
	signal CV, CH : std_logic_vector(9 downto 0);
	signal COLOR_R_i, COLOR_G_i, COLOR_B_i, GND_LINE, VERTICAL_LINE : std_logic_vector(3 downto 0);
	signal COLOR_MAX, COLOR_MIN : std_logic_vector(3 downto 0);
	signal COLOR_CH1, COLOR_CH2 : std_logic_vector(3 downto 0);
	--Signal Generator
	signal DATA_V : std_logic_vector(7 downto 0);
	signal DATA_F : std_logic_vector(7 downto 0);
	signal ADDA_S : std_logic_vector(9 downto 0);
	signal ENA_S : std_logic;
	signal REF_S : std_logic_vector(9 downto 0);
	signal READY_S : std_logic;
begin
    RESET_UART <= NOT RESET; --The UART DRIVER RESET is activated for 0 logic value
	--UART-RAM-REG DATA writer
	CONTROLLER_UART: CONTROL_UART port map(
	    READY => READY,
		RESET => RESET,
		  CLK => CLK,
		 DATA => DATA,
		 ADDA => ADDA,
		ENA_1 => ENA_1,
		ENA_2 => ENA_2,
	  ENA_MAX => ENA_MAX,
	  ENA_MIN => ENA_MIN);
	--UART RX DRIVER 1
	UART_DIVER_GRAPHIC: UART_RX generic map(
	    BAUDRATE => 115200,
        CLK_FREQ => 100000000)
    	    port map(
	       reset => RESET_UART,
             clk => CLK,
		      rx => RX,
		data_out => DATA,
		   ready => READY);
	--Memory RAM Block 1
	RAM_1: blk_mem_gen_0 port map(
	     clka => CLK,
		 clkb => CLK,
		  ena => ENA_1,
	   wea(0) => ENA_1,
		addra => ADDA,
		 dina => DATA,
		  enb => ENB_1,
		addrb => ADDB_1,
		doutb => DOUTB_1);
	--Memory RAM Block 2
    RAM_2: blk_mem_gen_0 port map(
	     clka => CLK,
		 clkb => CLK,
		  ena => ENA_2,
	   wea(0) => ENA_2,
		addra => ADDA,
		 dina => DATA,
		  enb => ENB_2,
		addrb => ADDB_2,
		doutb => DOUTB_2);
	--MAX Register
	MAX_REG: REG8B port map(
		    CLK => CLK,
	      RESET => RESET,
	     ENABLE => ENA_MAX,
	       DATA => DATA,
	   DATA_out => DATA_MAX);
	--MIN Register
	MIN_REG: REG8B port map(
	        CLK => CLK,
	      RESET => RESET,
	     ENABLE => ENA_MIN,
	       DATA => DATA,
	   DATA_out => DATA_MIN);
	--Controller of the VGA
	CONTROLLER_VGA: CONTROL_VGA port map(
	      CLK => CLK,
		RESET => RESET,
		 CH_o => CH,
		 CV_o => CV,
		HSYNC => HSYNC,
		VSYNC => VSYNC);
	--Data Path to communicate the values written in the RAM/Register with an VGA screen
	--Channel 1
	DATA_PATH_1: VGA_DATA port map(
	      CLK => CLK,
		RESET => RESET,
		   CH => CH,
		   CV => CV,
		 ADDB => ADDB_1,
		  ENB => ENB_1,
		DOUTB => DOUTB_1,
		COLOR => COLOR_CH1);
	--Channel 2
	DATA_PATH_2: VGA_DATA port map(
	      CLK => CLK,
		RESET => RESET,
		   CH => CH,
		   CV => CV,
		 ADDB => ADDB_2,
		  ENB => ENB_2,
		DOUTB => DOUTB_2,
		COLOR => COLOR_CH2);
	--GROUND LINE
	DATA_PATH_3: VGA_DATA port map(
	      CLK => CLK,
		RESET => RESET,
		   CH => CH,
		   CV => CV,
		--ADDB => ADDB_2,
		--ENB => ENB_2,
		DOUTB => "01111111", --Ground line printed
		COLOR => GND_LINE);
	--MAX VALUE
	DATA_PATH_4: VGA_DATA port map(
	      CLK => CLK,
		RESET => RESET,
		   CH => CH,
		   CV => CV,
		--ADDB => ADDB_2,
		--ENB => ENB_2,
		DOUTB => DATA_MAX,
		COLOR => COLOR_MAX);
	--MIN VALUE
	DATA_PATH_5: VGA_DATA port map(
	      CLK => CLK,
		RESET => RESET,
		   CH => CH,
		   CV => CV,
		--ADDB => ADDB_2,
		--ENB => ENB_2,
		DOUTB => DATA_MIN,
		COLOR => COLOR_MIN);
	--Vertical line
	VERTICAL: VGA_VERTICAL port map(
	       CH => CH,
	       CV => CV,
	    COLOR => VERTICAL_LINE);
	--Colour wires
	--Internal
	COLOR_R_i <= COLOR_CH1 or COLOR_MAX;
	COLOR_G_i <= COLOR_CH2;
	COLOR_B_i <= COLOR_MIN or COLOR_MAX;
    --To the VGA
	COLOR_B <= COLOR_B_i or GND_LINE or VERTICAL_LINE;
	COLOR_G <= COLOR_G_i or GND_LINE or VERTICAL_LINE;
	COLOR_R <= COLOR_R_i or GND_LINE or VERTICAL_LINE;
	--Signal Generator
	--UART RX DRIVER 1
	UART_DIVER_DDS: UART_RX generic map(
	    BAUDRATE => 70000,
        CLK_FREQ => 100000000)
		port map(
	       reset => RESET_UART,
             clk => CLK,
		      rx => RX_S,
		data_out => DATA_V,
		   ready => READY_S);
	--Register to store the DATA from the driver
	REG8B_DDS: REG8B port map(
	        CLK => CLK,
	      RESET => RESET,
	     ENABLE => READY_S,
	       DATA => DATA_V,
	   DATA_out => DATA_F);
	--Block to produce the modulated signal
	MODULATOR_DDS: MODULATOR port map(
	        CLK => CLK,
		  RESET => RESET,
		   DATA => DATA_F,
		   ADDA => ADDA_S,
		      S => S,
		    ENA => ENA_s);
	--Block of the ROM where the values of the Look Up Table are stored (with these values a sinus is made)
    ROM_DDS: blk_mem_rom port map(
	     clka => CLK,
          ena => ENA_S,
        addra => ADDA_S,
        douta => REF_S);
	--Block of the PWM to produce the carrier signal and the modulation one inside
	PWM_b: PWM port map(
	      CLK => CLK,
		RESET => RESET,
		  REF => REF_S,
		    Y => Y);
end A1;
