LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart_rx IS
  GENERIC (
    BAUDRATE : INTEGER := 115200;     -- Desired baudrate
    CLK_FREQ : INTEGER := 50000000  -- Input clock in Hz
  );
  PORT (
    reset    : IN  STD_LOGIC;
    clk      : IN  STD_LOGIC;
    rx       : IN  STD_LOGIC;
    data_out : OUT STD_LOGIC_VECTOR ( 7 DOWNTO 0 );
    ready    : OUT STD_LOGIC
  );
END uart_rx;


ARCHITECTURE uart_rx_arch OF uart_rx IS

  CONSTANT OVERSAMPLING    : INTEGER := 4;
  CONSTANT RX_CLK_PRESCALE : INTEGER := CLK_FREQ / ( OVERSAMPLING * BAUDRATE );

  TYPE uart_rx_states IS (WAIT_START, SET_PRSC, RECEIVE, WAIT_STOP);
  SIGNAL state : uart_rx_states;

  SIGNAL rx_clk_prsc    : STD_LOGIC_VECTOR(14 DOWNTO 0) := ( OTHERS => '0' ); -- rx_clk prescaler
  SIGNAL rx_clk         : STD_LOGIC := '0';                                   -- 4 x bit clock
  SIGNAL bit_cnt        : STD_LOGIC_VECTOR(3 DOWNTO 0) := ( OTHERS => '0' );  -- RX bit counter
  SIGNAL oversample_cnt : STD_LOGIC_VECTOR(1 DOWNTO 0) := ( OTHERS => '0' );  -- oversampling counter
  SIGNAL shreg          : STD_LOGIC_VECTOR(7 DOWNTO 0) := ( OTHERS => '0' );
  
BEGIN

-- rx_clk generation
  PR1: PROCESS( reset, clk )
  BEGIN
    IF ( reset = '0' ) THEN
      rx_clk_prsc <= (OTHERS => '0');
      rx_clk      <= '0';
    ELSIF rising_edge( clk ) THEN
      IF ( to_integer(UNSIGNED(rx_clk_prsc)) < ( RX_CLK_PRESCALE - 1 ) ) THEN
        rx_clk_prsc <= STD_LOGIC_VECTOR( UNSIGNED(rx_clk_prsc) + 1 );
        rx_clk      <= '0';
      ELSE
        rx_clk_prsc <= (OTHERS => '0');
        rx_clk      <= '1';
      END IF;
    END IF;
  END PROCESS;

-- receiving state machine
  PR2: PROCESS( reset, clk )
  BEGIN
    IF ( reset = '0' ) THEN
      state    <= WAIT_START;
      data_out <= (OTHERS => '0');
      ready    <= '0';
    ELSIF rising_edge( clk ) THEN
      IF ( rx_clk = '1' ) THEN
        CASE state IS
          WHEN WAIT_START =>
            IF ( rx = '0' ) THEN
              state          <= SET_PRSC;
              ready          <= '0';
              oversample_cnt <= (OTHERS => '0');
            END IF;

          WHEN SET_PRSC =>
            IF ( to_integer( UNSIGNED( oversample_cnt ) ) < ( ( OVERSAMPLING / 2 ) - 2 ) ) THEN
              oversample_cnt <= STD_LOGIC_VECTOR( UNSIGNED( oversample_cnt ) + 1 );
            ELSE
              oversample_cnt <= (OTHERS => '0');
              state          <= RECEIVE;
              bit_cnt        <= (OTHERS => '0');
            END IF;
          
          WHEN RECEIVE =>
            IF ( UNSIGNED( oversample_cnt ) = 3 ) THEN
              oversample_cnt    <= (OTHERS => '0');
              shreg(7)          <= rx;
              shreg(6 DOWNTO 0) <= shreg(7 DOWNTO 1);
              bit_cnt           <= STD_LOGIC_VECTOR( UNSIGNED( bit_cnt ) + 1 );
              IF ( UNSIGNED( bit_cnt ) = 7 ) THEN
                state    <= WAIT_STOP;
              END IF;
            ELSE
              oversample_cnt    <= STD_LOGIC_VECTOR( UNSIGNED( oversample_cnt ) + 1 );
            END IF;

          WHEN WAIT_STOP =>
            data_out <= shreg;
            ready    <= '1';
            IF ( rx = '1' ) THEN
              state <= WAIT_START;
            END IF;
        END CASE;
      END IF;
    END IF;
  END PROCESS;
  --data_out <= shreg; --YO
END uart_rx_arch;
