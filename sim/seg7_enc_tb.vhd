--------------------------------------------------------------------------------
--! Project  : eel4712c.lab2
--! Engineer : Chase Ruskin
--! Course   : Digital Design - EEL4712C
--! Created  : 2021-09-20
--! Entity   : seg7_enc_tb
--! Details  :
--!     Verifies functional behavior for `seg7_enc` entity using built-in 
--!     assertions and hard-coded look-up table.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library util;
use util.toolbox_pkg.all;
library work;

entity seg7_enc_tb is
    generic (
        COMMON_ANODE : boolean := true
    );
end entity;


architecture rtl of seg7_enc_tb is
    -- define signals to connect to UUT ports
    signal input  : std_logic_vector(3 downto 0);
    signal output : std_logic_vector(6 downto 0);

    -- store expected outputs in look-up table
    constant LUT : std_logic_vector(0 to output'length*(2**input'length)-1) :=
        "1000000" & -- 0
        "1111001" & -- 1
        "0100100" & -- 2
        "0110000" & -- 3
        "0011001" & -- 4
        "0010010" & -- 5
        "0000010" & -- 6
        "1111000" & -- 7
        "0000000" & -- 8
        "0011000" & -- 9
        "0001000" & -- 10
        "0000011" & -- 11
        "1000110" & -- 12
        "0100001" & -- 13
        "0000110" & -- 14
        "0001110";  -- 15

    constant DELAY : time := 10 ns;

begin
    --! instantiate the unit-under-test (UUT)
    uut : entity work.seg7_enc
    generic map (
        COMMON_ANODE => COMMON_ANODE
    ) port map (
        input  => input,
        output => output
    );

    -- verify behavior
    bench : process
        variable output_e : std_logic_vector(output'length-1 downto 0);
    begin
        -- test all possible inputs
        for ii in 15 downto 0 loop
            -- drive DUT input
            input <= std_logic_vector(to_unsigned(ii,input'length));
            -- wait some time for output
            wait for DELAY;
        
            -- index the ideal model to grab the correct bits for comparison
            output_e := LUT(ii*(output'length) to (ii+1)*(output'length)-1);

            -- invert expected output if common anode is disabled
            if COMMON_ANODE = false then
                output_e := not output_e;
            end if;

            -- assert output matches what is expected
            assert output = output_e report error_slv("output " & integer'image(ii), output, output_e) severity failure;
        end loop;

    report "Simulation complete.";
    wait;
    end process;

end architecture;