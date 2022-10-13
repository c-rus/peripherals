--------------------------------------------------------------------------------
--! Project  : eel4712c.lab2
--! Engineer : Chase Ruskin
--! Course   : Digital Design - EEL4712C
--! Created  : 2021-09-20
--! Entity   : seg7_enc
--! Details:
--!     Encodes a 4-bit binary input into corresponding output bits to drive a 
--!     seven segment display in common-anode or common-cathode configuration.
--!
--!     Enabling `COMMON_ANODE` will output segments to be interpreted as "on" 
--!     when that bit is '0'. Disabling `COMMON_ANODE` will output segments to 
--!     be interpreted as "on" when that bit is '1'.
--!
--!     The following illustration indicates the correspondence between segments
--!     and the bits of the `output` port:
--!                 0
--!             ========
--!        5  //      //  1
--!          //  6   //
--!          ========
--!     4  //      //  2
--!       //      //
--!       ========  
--!          3
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity seg7_enc is
    generic (
        --! determine if output is active-low (true) or active-high (false)
        COMMON_ANODE : boolean := true
    );
    port (
        input  : in  std_logic_vector(3 downto 0);
        output : out std_logic_vector(6 downto 0)
    );
end entity;


architecture rtl of seg7_enc is
    signal segments : std_logic_vector(6 downto 0);

begin
                -- decimal representations (0-9)
    segments <= "0111111" when (input = "0000") else
                "0000110" when (input = "0001") else
                "1011011" when (input = "0010") else
                "1001111" when (input = "0011") else
                "1100110" when (input = "0100") else
                "1101101" when (input = "0101") else
                "1111101" when (input = "0110") else
                "0000111" when (input = "0111") else
                "1111111" when (input = "1000") else
                "1100111" when (input = "1001") else
                -- hex representations (A-F)
                "1110111" when (input = "1010") else
                "1111100" when (input = "1011") else
                "0111001" when (input = "1100") else
                "1011110" when (input = "1101") else
                "1111001" when (input = "1110") else
                "1110001" when (input = "1111") else
                "0000000";
    
    process(segments)
    begin
        -- invert segments to adjust for common anode configuration
        if COMMON_ANODE = true then
            output <= not segments;
        else 
            output <= segments;
        end if;
    end process;

end architecture;