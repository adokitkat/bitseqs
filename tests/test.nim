import std/[sequtils, sugar]
import bitseqs

doAssert bit(0b1010'u8, 0) == 0
doAssert bit(0b1010'u8, 1) == 1
doAssert bit(0b1010'u8, 2) == 0
doAssert bit(0b1010'u8, 3) == 1

doAssert (0.Bit and 0.Bit) == 0.Bit
doAssert (0.Bit and 1.Bit) == 0.Bit
doAssert (1.Bit and 0.Bit) == 0.Bit
doAssert (1.Bit and 1.Bit) == 1.Bit

doAssert (0.Bit or 0.Bit) == 0.Bit
doAssert (0.Bit or 1.Bit) == 1.Bit
doAssert (1.Bit or 0.Bit) == 1.Bit
doAssert (1.Bit or 1.Bit) == 1.Bit

doAssert (0.Bit xor 0.Bit) == 0.Bit
doAssert (0.Bit xor 1.Bit) == 1.Bit
doAssert (1.Bit xor 0.Bit) == 1.Bit
doAssert (1.Bit xor 1.Bit) == 0.Bit

doAssert (not 0.Bit) == 1.Bit
doAssert (not 1.Bit) == 0.Bit

var
  x1: uint8 = 0b0111
  x2: uint8 = 0b1110
  x3: uint8 = 0b0000_1001
  x4: int16 = 0b0101

doAssert bit(x1, 0) == 1
doAssert bit(x1, 3) == 0
doAssert bit(x2, 0) == 0
doAssert bit(x2, 3) == 1

doAssert bits(x1).toSeq[^4..^1] == @[0.Bit, 1, 1, 1]
doAssert bits(x2).toSeq[^4..^1] == @[1.Bit, 1, 1, 0]
doAssert bits(x3).toSeq == @[0.Bit, 0, 0, 0, 1, 0, 0, 1]

doAssert newBitSeq() == @[]
doAssert newBitSeq(4) == @[0.Bit, 0, 0, 0]
doAssert newBitSeq(byte) == @[0.Bit, 0, 0, 0, 0, 0, 0, 0]

var
  b1: BitSeq = x1.toBitSeq
  b3: BitSeq = x3.toBitSeq
  b4: BitSeq = x4.toBitSeq

doAssert b1[^4..^1] == @[0.Bit, 1, 1, 1]
doAssert b3 == @[0.Bit, 0, 0, 0, 1, 0, 0, 1]
doAssert b4[^4..^1] == @[0.Bit, 1, 0, 1]

doAssert fromBitSeq[uint8](b1) == x1
doAssert fromBitSeq[uint8](b3) == x3
doAssert fromBitSeq[uint16](b4) == cast[uint16](x4)

doAssert x1.bitsIdxOnSeq.len == 3
doAssert x3.bitsIdxOnSeq.len == 2
doAssert x4.bitsIdxOnSeq.len == 2

doAssert x1.bitsIdxOffSeq.len == 5 # uint8 => 8 - 3 = 5

doAssert b1.bitsIdxOnSeq.len == 3
doAssert b1.bitsIdxOn.toSeq.len == 3

doAssert (b1 and b3)[^4..^1] == @[0.Bit, 0, 0, 1]
doAssert (b1 or b3)[^4..^1] == @[1.Bit, 1, 1, 1]
doAssert (b1 xor b3)[^4..^1] == @[1.Bit, 1, 1, 0]
doAssert (not b1)[^4..^1] == @[1.Bit, 0, 0, 0]

b1.and= b3
doAssert b1[^4..^1] == @[0.Bit, 0, 0, 1]
b1.or= b3
doAssert b1[^4..^1] == @[1.Bit, 0, 0, 1]
b1.xor= b3
doAssert b1[^4..^1] == @[0.Bit, 0, 0, 0]
doAssert not(b1[^4..^1]) == @[1.Bit, 1, 1, 1]

b1[^1] = 1
doAssert b1 == @[0.Bit, 0, 0, 0, 0, 0, 0, 1]
b1[^2] = 1
doAssert b1 == @[0.Bit, 0, 0, 0, 0, 0, 1, 1]
b1[0] = 1
doAssert b1 == @[1.Bit, 0, 0, 0, 0, 0, 1, 1]

var b13 = b1[0..3].concat(b3[^4..^1])
doAssert b13 == @[1.Bit, 0, 0, 0, 1, 0, 0, 1]
doAssert b13.count(1) == 3
doAssert fromBitSeq[uint8](b13) == 0b1000_1001
doAssert fromBitSeq[uint16](b13) == 0b1000_1001
doAssert fromBitSeq[BiggestUInt](b13) == 0b1000_1001

b13 = b1.concat(b3)
doAssert b13 == @[1.Bit, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1]
doAssert fromBitSeq[BiggestUInt](b13) == 0b1000_0011_0000_1001
doAssert fromBitSeq[uint16](b13) == 0b1000_0011_0000_1001
doAssert fromBitSeq[uint8](b13) == 0b0000_0000_0000_1001
doAssert fromBitSeq[uint8](b13).toBitSeq ==  @[0.Bit, 0, 0, 0, 1, 0, 0, 1]

var
  x5: int64 = int64.high
  b5: BitSeq = x5.toBitSeq
doAssert b5 == @[0.Bit] & @[1.Bit].cycle(63)
var b55 = b5 & b5
doAssert b55 == @[0.Bit] & @[1.Bit].cycle(63) & @[0.Bit] & @[1.Bit].cycle(63)
doAssert fromBitSeq[uint64](b55[0..63]) == cast[uint64](int64.high)
doAssert fromBitSeq[uint64](b55[0..63]).toBitSeq == @[0.Bit] & @[1.Bit].cycle(63)
doAssert fromBitSeq[uint64](b55[1..64]).toBitSeq == @[1.Bit].cycle(63) & @[0.Bit]
doAssert fromBitSeq[uint64](b55[1..65]).toBitSeq == @[1.Bit].cycle(62) & @[0.Bit] & @[1.Bit] # basically b55[2..65]

var b6: BitSeq = @[1.Bit, 0, 1, 0]
b6.resize(8)
doAssert b6 == @[0.Bit, 0, 0, 0, 1, 0, 1, 0]
b6.resize(4)
doAssert b6 == @[1.Bit, 0, 1, 0]
b6.resize(uint16)
doAssert b6 == @[0.Bit].cycle(12) & @[1.Bit, 0, 1, 0]
b6.resize(byte)
doAssert b6 == @[0.Bit, 0, 0, 0, 1, 0, 1, 0]
b6.resize(5)
doAssert b6 == @[0.Bit, 1, 0, 1, 0]
b6.resize(1)
doAssert b6 == @[0.Bit]
b6.resize(0)
doAssert b6 == @[]
b6.resize(byte)
doAssert b6 == @[0.Bit].cycle(8)

var b7: BitSeq = @[1.Bit, 0, 1, 0]
b7.bitFlip(0)
doAssert b7 == @[0.Bit, 0, 1, 0]
b7.bitFlip(3)
doAssert b7 == @[0.Bit, 0, 1, 1]
doAssert b7.dup(bitFlip(3)) == @[0.Bit, 0, 1, 0] # Duplicates `b7` first and flips bit 3
doAssert b7 == @[0.Bit, 0, 1, 1] # Original `b7` is unchanged
b7.bitFlip(2..3)
doAssert b7 == @[0.Bit, 0, 0, 0]

b7.bitSet(0, 1.Bit)
doAssert b7 == @[1.Bit, 0, 0, 0]
b7.bitSet(1..3, 1.Bit)
doAssert b7 == @[1.Bit, 1, 1, 1]
b7.bitSet(0..^1, 0.Bit)
doAssert b7 == @[0.Bit, 0, 0, 0]
b7.bitSet(^3..^2, 1.Bit)
doAssert b7 == @[0.Bit, 1, 1, 0]

b7.bitFlip(^3..^2)
doAssert b7 == @[0.Bit, 0, 0, 0]
b7.bitFlip(^4..1)
doAssert b7 == @[1.Bit, 1, 0, 0]