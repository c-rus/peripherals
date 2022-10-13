--------------------------------------------------------------------------------
--! Project  : eel4712c.lab5
--! Engineer : Chase Ruskin
--! Course   : Digital Design - EEL4712C
--! Created  : 2021-10-16
--! Entity   : bcd_enc_tb
--! Details  :
--!		Validates the functionality for the bcd_enc entity using test vector
--!		files generated from bcd_enc_tb.py. 
--!		
--!		Ability to test generics SIZE and DIGITS. Performs in-line assertions 
--!		for BCD output and its `ovfl` flag.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library util;
use util.toolbox_pkg.all;
use std.textio.all;
library work;

entity bcd_enc_tb is
	generic(
		SIZE   : positive := 4;
		DIGITS : positive := 2
	);
end entity;


architecture rtl of bcd_enc_tb is
	-- declare signals to connect to the DUT
	signal clk   : std_logic := '0';
	signal rst_n : std_logic := '0';
	signal go 	 : std_logic := '0';
	signal bin   : std_logic_vector(SIZE-1 downto 0);
	signal bcd   : std_logic_vector((4*DIGITS)-1 downto 0);
	signal done  : std_logic;
	signal ovfl  : std_logic;

	signal halt : std_logic := '0';

	constant clk_period : time := 10 ns;

begin
	--! instantiate the DUT
	uut : entity work.bcd_enc
	generic map (
		SIZE   => SIZE,
		DIGITS => DIGITS
	) port map (
		clk   => clk,
		rst_n => rst_n,
		go    => go,
		bin   => bin,
		bcd   => bcd,
		done  => done,
		ovfl  => ovfl
	);

	--! generate clock
	clk <= not clk after clk_period/2 when(halt = '0');

	--! perform initial reset
	boot : process
	begin
		rst_n <= '0';
		wait for clk_period*4;
		rst_n <= '1';
		wait;
	end process;
	
	--! verify the DUT's behavior
	bench : process
		-- file IO variables
		file in_file  : text open read_mode is "inputs.txt";
		file out_file : text open read_mode is "outputs.txt";
		-- assertion variables
        variable digit_e : std_logic_vector(3 downto 0);
		variable digit_r : std_logic_vector(3 downto 0);
		variable ovfl_e  : std_logic;
	begin
		wait until rst_n = '1';
        while not endfile(in_file) loop
			go <= '1';
            -- drive DUT inputs
			bin <= read_str_to_slv(in_file, bin'length);

			wait until rising_edge(clk);
			go <= '0';

			-- wait for output
            wait until rising_edge(clk) and done = '1';

			-- compare with expected results
			-- @note: file stores most significant digit first
			for ii in DIGITS-1 downto 0 loop
				-- index from received vector 
				digit_r := bcd((4*(ii+1))-1 downto (4*ii));
				-- read expected vector
				digit_e := read_str_to_slv(out_file, 4);

				assert digit_r = digit_e report error_slv("digit " & integer'image(ii), digit_r, digit_e) severity failure;
			end loop;
			-- read overflow bit from file
			ovfl_e := read_str_to_sl(out_file);
			assert ovfl = ovfl_e report error_sl("overflow", ovfl, ovfl_e) severity failure;
			go <= '0';
			-- give one cycle of go being disabled to allow for state transition back to INITIAL
			wait until rising_edge(clk);
        end loop;

		-- all test vectors have been evaluated; simulation is complete
        report "Simulation complete.";
		halt <= '1';
		wait;
	end process;

end architecture;