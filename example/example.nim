import std/[sequtils, sugar]
import bitfields

#              MSB -> 0101 1100 <- LSB
let number: uint8 = 0b0101_1100

# Get a `Bit` (range[0'u8..1'u8]) from a number
# Indexed from LSB (right side)
#        7654 3210
# MSB -> 0101 1100 <- LSB
assert number.bit(0) == 0.Bit
assert number.bit(3) == 1.Bit
assert number.bit(7) == 0.Bit
assert number.bits().toSeq() == @[0.Bit, 1, 0, 1, 1, 1, 0, 0] # `toSeq` is from std/sequtils

# Perform bitwise operations on bits
#                  0  or            1   == 1
assert (number.bit(1) or number.bit(2)) == 1.Bit

# Create `BitField` (seq[Bit])
# Indexed from MSB (left side)
#        0123 4567
# MSB -> 0101 1100 <- LSB
let bf = number.toBitField()
assert bf == @[0.Bit, 1, 0, 1, 1, 1, 0, 0]

# Get data back from `BitField` as uint8 - uint64
assert fromBitfield[uint8](bf) == 0b0101_1100

# Use any seq operations on `BitField`
assert bf.filterIt(it == 1.Bit).len == 4

# Get a seq of indexes of bits set to 1/0
# Indexed from MSB (left side)
#         1 3 45
# MSB -> 0101 1100 <- LSB
assert number.bitsIdxOnSeq() == @[1, 3, 4, 5]
assert bf.bitsIdxOn.toSeq() == @[1, 3, 4, 5]
#        0 2    67
# MSB -> 0101 1100 <- LSB
assert bf.bitsIdxOffSeq() == @[0, 2, 6, 7]

# Create a new empty `BitField`
var bf2 = newBitField(uint8) # == newBitField(8)
for i in 0..<4:
  bf2[i] = 1.Bit
assert bf2 == @[1.Bit, 1, 1, 1, 0, 0, 0, 0]

# Perform bitwise operations on `BitFields`
assert (bf and bf2) == @[0.Bit, 1, 0, 1, 0, 0, 0, 0]
assert (bf xor bf2) == @[1.Bit, 0, 1, 0, 1, 1, 0, 0]
var bf3 = not bf2
assert bf3 == @[0.Bit, 0, 0, 0, 1, 1, 1, 1]

# Flip `Bits` in `BitFields`
bf2.bitFlip(0)
assert bf2 == @[0.Bit, 1, 1, 1, 0, 0, 0, 0]
bf2.bitFlip(0..3)
assert bf2 == @[1.Bit, 0, 0, 0, 0, 0, 0, 0]
bf2.bitFlip(^2)
assert bf2 == @[1.Bit, 0, 0, 0, 0, 0, 1, 0]

bf3.bitFlip(3..^1)
assert bf3 == @[0.Bit, 0, 0, 1, 0, 0, 0, 0]
# With `dup()` from std/sugar it doesn't mutate original
assert bf3.dup(bitFlip(0)) == @[1.Bit, 0, 0, 1, 0, 0, 0, 0]

# Set `Bits` in `BitFields`
bf3.bitSet(0, 1)
assert bf3 == @[1.Bit, 0, 0, 1, 0, 0, 0, 0]
bf3.bitSet(1..3, 1)
assert bf3 == @[1.Bit, 1, 1, 1, 0, 0, 0, 0]
bf3.bitSet(^3..^1, 1)
assert bf3 == @[1.Bit, 1, 1, 1, 0, 1, 1, 1]

# Resize `BitFields`
# If `size` is smaller than `bf.len`, the most significant bits are dropped
# If `size` is larger than `bf.len`, the most significant bits are padded with 0
bf3.resize(4)
assert bf3 == @[0.Bit, 1, 1, 1]
bf3.resize(uint8) 
assert bf3 == @[0.Bit, 0, 0, 0, 0, 1, 1, 1]
