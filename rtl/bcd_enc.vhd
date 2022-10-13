--------------------------------------------------------------------------------
--! Project  : eel4712c.lab5
--! Engineer : Chase Ruskin
--! Course   : Digital Design - EEL4712C
--! Created  : 2021-10-16
--! Entity   : bcd_enc
--! Details  :
--!     Encodes a binary number `bin` into a binary-coded decimal number `bcd` 
--!     using the "double dabble" algorithm. 
--!     
--!     Implemented with a 2-process FSMD. If at any point during the  
--!     computation the input number changes, the algorithm resets. On the same
--!     cycle that done is asserted, the output is ready on `bcd` and `ovfl`.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity bcd_enc is
    generic (
        --! width of incoming binary number
        SIZE : positive := 4; 
        --! number of decimal digits to use
        DIGITS : positive := 2 
    );
    port (
        clk   : in  std_logic;
        --! active-low
        rst_n : in  std_logic;  
        --! enable flag (starts the algorithm)
        go    : in  std_logic;  
        bin   : in  std_logic_vector(SIZE-1 downto 0);
        bcd   : out std_logic_vector((4*DIGITS)-1 downto 0);
        done  : out std_logic;
        --! flag to indicate if not enough digits were specified
        ovfl  : out std_logic   
    );
end entity;


architecture rtl of bcd_enc is

    type state is (S_INITIAL, S_LOAD, S_SHIFT, S_ADD, S_COMPLETE);

    -- register and next-cycle wire for dabble
    signal dabble_r : std_logic_vector(bcd'length+bin'length-1 downto 0);
    signal dabble_d : std_logic_vector(bcd'length+bin'length-1 downto 0);

    -- register and next-cycle wire for overflow
    signal ovfl_r : std_logic;
    signal ovfl_d : std_logic;

    -- register and next-cycle wire for state
    signal state_r : state;
    signal state_d : state;

    -- register to store the current bianry representation being processed
    signal bin_r : std_logic_vector(SIZE-1 downto 0);

    -- amount of bits needed is how many are to be used to represent binary input's bit width
    constant CTR_SIZE : positive := positive(ceil(log2(real(SIZE + 1))));
    constant MAX_CTR : std_logic_vector(CTR_SIZE-1 downto 0) := std_logic_vector(to_unsigned(SIZE-1, CTR_SIZE));

    -- register and next-cycle wire for counter
    signal ctr_r : std_logic_vector(CTR_SIZE-1 downto 0);
    signal ctr_d : std_logic_vector(CTR_SIZE-1 downto 0);

begin
    -- simple pass-through
    ovfl <= ovfl_r;

    --! combinational logic to determine next state and output signals
    process(state_r, ctr_r, dabble_r, ovfl_r, go, bin)
        variable tmp_bcd_digit : std_logic_vector(3 downto 0);
    begin
        -- defaults
        state_d <= state_r;
        ctr_d <= ctr_r;
        ovfl_d <= ovfl_r;
        dabble_d <= dabble_r;
        done <= '0';
        bcd <= dabble_r(dabble_r'length-1 downto SIZE);

        case state_r is
            --! initial "boot-up" state
            when S_INITIAL =>
                -- transition to S_SHIFT when enabled
                if go = '1' then
                    state_d <= S_LOAD;
                end if;

            --! collect data for algorithm computation
            when S_LOAD => 
                -- load in binary number
                dabble_d <= (others => '0');
                dabble_d(bin'length-1 downto 0) <= bin;
                -- reset the counter
                ctr_d <= (others => '0');
                ovfl_d <= '0';
                -- transition to begin the algorithm
                state_d <= S_SHIFT;
            
            --! perform "double" (multiply by 2)
            when S_SHIFT =>
                -- perform left S_SHIFT
                dabble_d <= dabble_r(dabble_r'length-2 downto 0) & '0';
                -- trip when the bit getting pushed off is a '1'
                ovfl_d <= ovfl_r or dabble_r(dabble_r'length-1);
                -- increment the counter
                ctr_d <= std_logic_vector(unsigned(ctr_r) + 1);
                -- algorithm is done when the current count reaches MAX_CTR
                if ctr_r = MAX_CTR then
                    state_d <= S_COMPLETE;
                -- otherwise continue the algorithm
                else
                    state_d <= S_ADD;
                end if;
            
            --! perform "dabble" (+3 when >=5)
            when S_ADD =>
                -- evaluate every BCD digit at this stage
                for ii in DIGITS-1 downto 0 loop
                    tmp_bcd_digit := dabble_r((4*(ii+1))+SIZE-1 downto (4*ii)+SIZE);
                    -- add 3 to bcd digit when the value is greater than or equal to 5
                    if tmp_bcd_digit >= std_logic_vector(to_unsigned(5, tmp_bcd_digit'length)) then
                        dabble_d((4*(ii+1))+SIZE-1 downto (4*ii)+SIZE) <= std_logic_vector(unsigned(tmp_bcd_digit) + 3);
                    end if;

                end loop;
                -- transition back to S_SHIFT
                state_d <= S_SHIFT;

            --! algorithm complete; output results
            when S_COMPLETE =>
                -- signify that the output data is valid
                done <= '1';
                -- output overflow flag
                ovfl_d <= ovfl_r;
                -- transition back to S_INITIAL
                if go = '1' then
                    state_d <= S_LOAD;
                end if;

            --! default case
            when others =>
                null;
        end case;

        -- check if go is valid and the current incoming number is not the 
        -- number stored in register to perform interruption and reset algorithm
        if go = '1' and bin /= bin_r then
            state_d <= S_LOAD;
        end if;

    end process;
    
    --! sequential logic for storing FSM registers
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            ovfl_r <= '0';
            dabble_r <= (others => '0');
            bin_r <= (others => '0');
            ctr_r <= (others => '0');
            state_r <= S_INITIAL;
        elsif rising_edge(clk) then
            state_r <= state_d;
            ctr_r <= ctr_d;
            ovfl_r <= ovfl_d;
            dabble_r <= dabble_d;
            bin_r <= bin;
        end if;
    end process;

end architecture;