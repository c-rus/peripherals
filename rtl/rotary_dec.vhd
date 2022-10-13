--------------------------------------------------------------------------------
--! Project  : peripherals.rotary_dec
--! Engineer : Chase Ruskin
--! Course   : Digital Design - EEL4712C
--! Created  : October 11, 2021
--! Entity   : rotary_dec
--! Details  :
--!     Decodes a rotary-encoded signal along `channel_a` and `channel_b` into 
--!     a `left` direction signal and `valid` flag. 
--!
--!     Clock-wise rotations output left = '0' and counter-clock-wise rotations 
--!     output left = '1'. Channels are intepreted as active-low. Valid is
--!     raised for a single cycle before having to wait to return to S_NEUTRAL 
--!     state.
--!
--!             left        valid
--!     CW      0           1
--!     CCW     1           1
--!
--! Schematic: 
--!              A --    / s1
--!     GND <|-- C -- (|)
--!              B --    \ s2
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rotary_dec is
    generic (
        --! time to wait between sampling incoming signals
        DEBOUNCE_PERIOD : natural := 1
    );
    port (
        clk       : in   std_logic;
        rst_n     : in   std_logic;
        --! enable flag
        go        : in   std_logic; 
        --! left pin of bottom 3
        channel_a : in   std_logic; 
        --! right pin of bottom 3
        channel_b : in   std_logic; 
        --! left, /right
        left      : out  std_logic;
        --! output valid flag
        valid     : out  std_logic  
    );
end entity;


architecture rtl of rotary_dec is

    type state is (S_NEUTRAL, S_TRIGGER_L, S_TRIGGER_R, S_AWAIT_SYNC); 

    -- register and next-cycle wire for state
    signal state_r : state;
    signal state_d : state;

    signal clk_out : std_logic;
    signal enable_clk_n : std_logic;

begin
    -- implement debouncing logic
    debouncer : entity eel4712c.clk_gen
    generic map(
        ms_period => DEBOUNCE_PERIOD
    )
    port map(
        clk50MHz=>clk,
        rst=>(not rst_n),
        button_n=>enable_clk_n,
        clk_out=>clk_out
    );

    -- process to compute the encoder's next state
    process(state_r, go, channel_a, channel_b)
    begin
        -- set defaults
        state_d <= state_r;
        enable_clk_n <= '1';
        left <= '1';
        valid <= '0';

        -- compute only when enabled
        if go = '1' then 
            case state_r is
                --! read the channels
                when S_NEUTRAL =>                    
                    -- rotate right turns off left pin first (channel_a)
                    if channel_a = '0' and channel_b = '1' then
                        state_d <= S_TRIGGER_R;
                        enable_clk_n <= '0';
                    -- rotate left turns off right pin first (channel_b)
                    elsif channel_a = '1' and channel_b = '0' then
                        state_d <= S_TRIGGER_L;
                        enable_clk_n <= '0';
                    end if;

                --! left rotation
                when S_TRIGGER_L =>
                    -- turning left
                    left <= '1';
                    -- only send valid = '1' for single cycle
                    valid <= '1';
                    state_d <= S_AWAIT_SYNC;

                --! right rotation
                when S_TRIGGER_R =>
                    -- turning right
                    left <= '0';
                    -- only send valid = '1' for single cycle
                    valid <= '1';
                    state_d <= S_AWAIT_SYNC;

                --! await for channels to be resynchronized to resting state
                when S_AWAIT_SYNC => 
                    valid <= '0';
                    
                    if channel_a = '1' and channel_b = '1' then
                        state_d <= S_NEUTRAL;
                        enable_clk_n <= '0';
                    end if;

                --! default case
                when others =>
                    null;
            end case;
        end if;

    end process;

    -- process to store the encoder's next-cycle state_d outputs
    process(rst_n, clk) begin
        if rst_n = '0' then
            state_r <= S_NEUTRAL;
        elsif rising_edge(clk) then
            -- state reg operates on clock with slow pulse (enable) to debounce buttons
            if go = '1' and clk_out = '1' then
                state_r <= state_d;
            end if;

        end if;
    end process;

end architecture;