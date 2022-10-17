--------------------------------------------------------------------------------
-- Project: io.rotary_dec
-- Author: Chase Ruskin
-- Course: Digital Design - EEL4712C
-- Creation Date: October 11, 2021
-- Entity: rotary_dec_tb
-- Description:
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library util;
use util.toolbox_pkg.all;

entity rotary_dec_tb is
end entity;

architecture rtl of rotary_dec_tb is

	--declare the design-under-test (DUT) component
	component rotary_dec is
		port(
			clk       : in   std_logic;
			rst_n     : in   std_logic;
			go        : in   std_logic; --enable flag
			channel_a : in   std_logic; --left pin of bottom 3
			channel_b : in   std_logic; --right pin of bottom 3
			left      : out  std_logic; --left, /right
			valid     : out  std_logic  --output valid flag
		);
	end component;

	--declare signals to connect to the DUT
	constant WIDE : positive := 4;

	signal clk   : std_logic := '0';
	signal rst_n : std_logic := '1';
	signal go 	 : std_logic := '0';
	signal channel_a : std_logic := '0';
	signal channel_b : std_logic := '0';
	signal left : std_logic;
	signal valid : std_logic;

	constant PERIOD : time := 20 ns;
	signal halt : std_logic := '0';

begin
	--instantiate the DUT
	uX : rotary_dec
	port map(
		clk=>clk,
		rst_n=>rst_n,
		go=>go,
		channel_a=>channel_a,
		channel_b=>channel_b,
		left=>left,
		valid=>valid
	);

	--50% duty clock cycle
	clk <= not clk after PERIOD/2 when halt = '0';

	--power-on reset
	bootup : process
	begin
		rst_n <= '0';
		wait for PERIOD*3;
		rst_n <= '1';
		wait;
	end process;

	--verify the DUT's behavior
	bench : process
	begin
		go <= '1';
		wait until rst_n = '1';

		report "ROTATE RIGHT";
		-- rotate right
		for ii in 0 to 20 loop
			channel_a <= '0';
			channel_b <= '1';
			wait until valid = '1';

			report "is left: " & std_logic'image(left) & " valid: " & std_logic'image(valid);
			channel_a <= '1';
			channel_b <= '1';
			wait until rising_edge(clk);
			wait until rising_edge(clk);
		end loop;

		report "ROTATE LEFT";
		-- rotate left
		for ii in 0 to 20 loop
			channel_a <= '1';
			channel_b <= '0';
			wait until valid = '1';

			report "is left: " & std_logic'image(left) & " valid: " & std_logic'image(valid);
			channel_a <= '1';
			channel_b <= '1';
			wait until rising_edge(clk);
			wait until rising_edge(clk);
		end loop;

		report "ROTATE RIGHT";
		-- rotate right
		for ii in 0 to 3 loop
			channel_a <= '0';
			channel_b <= '1';
			wait until valid = '1';

			report "is left: " & std_logic'image(left) & " valid: " & std_logic'image(valid);
			channel_a <= '1';
			channel_b <= '1';
			wait until rising_edge(clk);
			wait until rising_edge(clk);
		end loop;

		report "Simulation complete.";
		halt <= '1';
		wait;
	end process;


end architecture;