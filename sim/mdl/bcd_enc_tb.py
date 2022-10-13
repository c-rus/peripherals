# Project  : eel4712c.lab5
# Engineer : Chase Ruskin
# Course   : EEL4712C - Digital Design
# Created  : 10/17/2021
# Script   : bcd_enc_tb.py
# Details  :
#   This script generates the I/O test vector files to be used with the 
#   bcd_enc_tb.vhd testbench. Generic values for `DIGITS`` and `SIZE` can be 
#   passed through the command-line.
#
import random
from toolbox import toolbox as tb

# --- Constants ----------------------------------------------------------------

MAX_SIMS = 1_000
R_SEED = 9

# --- Logic --------------------------------------------------------------------

# enter seed for consistent input vectors if running at max simulation cap
random.seed(R_SEED)

# create empty test vector files
input_file = open('inputs.txt', 'w')
output_file = open('outputs.txt', 'w')

# collect generics from command-line and HDL testbench
generics = tb.get_generics()

# set/collect generics
DIGITS = int(generics['DIGITS'])
WIDTH  = int(generics['SIZE'])

# cap simulation count for saving time/computations
SIM_COUNT = 2**WIDTH if(2**WIDTH < MAX_SIMS) else MAX_SIMS

# the algorithm
for word in range(0, SIM_COUNT):
    # perform random inputs if unable to test all combinations
    if(SIM_COUNT == MAX_SIMS):
        word = random.randint(0, (2**WIDTH)-1)
    # write each number to input file
    tb.write_bits(input_file, 
        tb.to_bin(word, WIDTH))

    # separate each digit
    digits = []
    while word >= 10:
        digits.insert(0, (word % 10))
        word = int(word/10)
    digits.insert(0, word)
    
    # check if an overflow exists on conversion given digit constraint
    ovfl = 0
    diff = DIGITS - len(digits)
    if(diff < 0):
        ovfl = 1
        # trim off left-most digits
        digits = digits[abs(diff):]
    # pad left-most digit positions with 0's
    elif(diff > 0):
        for i in range(diff):
            digits.insert(0, 0)

    # write each digit to output file
    bin_digits = ''
    for d in digits:
        tb.write_bits(output_file, tb.to_bin(d, 4))
    # write out each overflow to output file
    tb.write_bits(output_file, ovfl)
    pass
