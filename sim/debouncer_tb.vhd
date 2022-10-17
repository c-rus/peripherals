--------------------------------------------------------------------------------
--! Project   : crus.io.peripherals
--! Engineer  : Chase Ruskin
--! Created   : 2022-10-14
--! Testbench : debouncer_tb
--! Details   :
--!     @todo: write general overview of component and its behavior
--!
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- @note: uncomment the next 3 lines to use the toolbox package.
-- library util;
-- use util.toolbox_pkg.all;
-- use std.textio.all;

entity debouncer_tb is 
    -- @todo: define generic interface (if applicable)
end entity debouncer_tb;


architecture sim of debouncer_tb is
    --! unit-under-test (UUT) interface wires
    signal clk    : std_logic := '0';
    signal rst    : std_logic;
    signal input  : std_logic;
    signal output : std_logic;

    -- generate 1kHz pulse
    constant CLK_IN_FREQ  : natural := 50_000_000;
    constant CLK_OUT_FREQ : natural := 1_000;

    --! internal testbench signals

    constant DELAY : time := 1 ms;

    -- clock period for 50 MHz clock
    constant PERIOD : time := 20 ns;

    signal halt : std_logic := '0';
begin
    --! UUT instantiation
    uut : entity work.debouncer
    generic map (
        CLK_IN_FREQ  => CLK_IN_FREQ,
        CLK_OUT_FREQ => CLK_OUT_FREQ
    ) port map (
        clk    => clk,
        rst    => rst,
        input  => input,
        output => output
    );

	--! generate clock
	clk <= not clk after PERIOD/2 when(halt = '0');

	--! perform initial reset
	boot : process
	begin
		rst <= '1';
		wait for PERIOD*4;
		rst <= '0';
		wait;
	end process;

    --! assert the received outputs match expected model values
    bench: process
        --! @todo: define variables for checking output ports
    begin
        input <= '0';
        wait until rst = '0';

        assert output = '0' severity failure;

        input <= '1';
        assert output = '0' severity failure;
        wait for DELAY;
        wait until rising_edge(clk);
        assert output = '0' severity failure;
        wait for DELAY;
        wait until rising_edge(clk);
        assert output = '1' severity failure;

        input <= '0';
        assert output = '1' severity failure;
        wait for DELAY;
        wait until rising_edge(clk);
        assert output = '1' severity failure;
        wait for DELAY;
        wait until rising_edge(clk);
        assert output = '0' severity failure;

        -- halt the simulation
        report "Simulation complete.";
        halt <= '1';
        wait;
    end process;

end architecture sim;