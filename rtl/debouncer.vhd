--------------------------------------------------------------------------------
--! Project  : io.peripherals
--! Engineer : Chase Ruskin
--! Created  : 2022-10-14
--! Entity   : debouncer
--! Details  :
--!     @todo: write general overview of component and its behavior
--!
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library chrono;

-- @TODO: under construction

entity debouncer is 
    generic (
        CLK_IN_FREQ  : natural;
        CLK_OUT_FREQ : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        input : in std_logic;
        output : out std_logic
    );
end entity debouncer;


architecture rtl of debouncer is
    -- indicator to enable capturing the next-state logic
    signal en_sample : std_logic;

    -- registers
    signal capture_1_r : std_logic;
    signal capture_2_r : std_logic;

begin
    -- slow the sampling rate
    u_sampler : entity chrono.clk_div
    generic map (
        CLK_IN_FREQ  => CLK_IN_FREQ,
        CLK_OUT_FREQ => CLK_OUT_FREQ
    ) port map (
        clk_src => clk,
        rst     => rst,
        clk_tgt => en_sample
    );

    -- create 2 registers to capture state over time
    process(clk, rst) 
    begin
        if rst = '1' then
            capture_1_r <= '0';
            capture_2_r <= '0';
        elsif rising_edge(clk) then
            if en_sample = '1' then
                capture_1_r <= input;
                capture_2_r <= capture_1_r;
            end if;
        end if;
    end process;

    -- change value when the value is steady (visible on both registers)
    output <= capture_1_r and capture_2_r;
    
end architecture rtl;