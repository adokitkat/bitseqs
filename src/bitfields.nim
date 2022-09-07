import std/[enumerate, sequtils]

type
  Bit* = range[0'u8..1'u8]
  BitField* = seq[Bit]

template `^^`(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))

func bit*[T: SomeOrdinal](value: T, pos: Natural): Bit {.inline.} =
  ## Get a `Bit` at position `pos` from `value`.
  ## Indexed from 0, least significant bit first.
  runnableExamples:
    doAssert bit(0b1010'u8, 0) == 0
    doAssert bit(0b1010'u8, 1) == 1
    doAssert bit(0b1010'u8, 2) == 0
    doAssert bit(0b1010'u8, 3) == 1
  
  result = Bit((value and (1.T shl pos)) shr pos)

iterator bits*[T: SomeOrdinal](value: T): Bit {.inline.} =
  ## Iterate over all `Bits` in `value`.
  for i in countdown(sizeof(value) * 8 - 1, 0):
    yield bit(value, i)

func `and`*(x, y: Bit): Bit {.inline.} = Bit(x.uint8 and y.uint8)
func `or`*(x, y: Bit): Bit {.inline.} = Bit(x.uint8 or y.uint8)
func `xor`*(x, y: Bit): Bit {.inline.} = Bit(x.uint8 xor y.uint8)
func `not`*(x: Bit): Bit {.inline.} = Bit(1 - x.uint8)

## Initializes a `BitField`
func newBitField*(): BitField = newSeq[Bit]()
func newBitField*(size: Natural): BitField = newSeq[Bit](size)
func newBitField*(typ: typedesc): BitField = newSeq[Bit](sizeof(typ) * 8)

func toBitField*[T: SomeOrdinal](value: T): BitField =
  ## Construct a `BitField` from `value`.'
  ## Indexed from 0, least significant bit last.
  runnableExamples:
    let bf = toBitField(0b1010'u8)
    doAssert bf == @[0.Bit, 0, 0, 0, 1, 0, 1, 0] # 8 bit long because of u8
    doAssert bf[^4..^1] == @[1.Bit, 0, 1, 0] # slice of last 4 bits
    doAssert bf[^4] == 1.Bit
    doAssert bf[^1] == 0.Bit # last bit
  
  result = newSeq[Bit](sizeof(value) * 8)
  for pos, i in enumerate(countdown(sizeof(value) * 8 - 1, 0)):
    result[i] = bit(value, pos)

func fromBitfield*[T: typedesc(SomeUnsignedInt)](value: BitField): T =
  ## Construct a `SomeUnsignedInt` from `value`.
  runnableExamples:
    var bf1 = @[1.Bit, 0, 0, 0, 1, 0, 0, 1]
    doAssert fromBitfield[uint8](bf1) == 0b1000_1001
    doAssert fromBitfield[uint16](bf1) == 0b1000_1001
    doAssert fromBitfield[BiggestUInt](bf1) == 0b1000_1001
    var bf2 = @[1.Bit].cycle(8) & bf1
    doAssert fromBitfield[uint8](bf2) == 0b1111_1111_1000_1001
    doAssert fromBitfield[uint8](bf2) == 0b0000_0000_1000_1001

  result = 0
  var
    i = 0
    bit: Bit = 0
  for x in zip(toSeq(countdown(value.len - 1, 0)), value):
    (i, bit) = x
    result = result or (T(bit) shl i)

func resize*(bf: var BitField, size: Natural) = 
  ## Resize `bf` to `size`.
  ## If `size` is smaller than `bf.len`, the most significant bits are dropped.
  ## If `size` is larger than `bf.len`, the most significant bits are padded with 0.
  runnableExamples:
    var bf: BitField = @[1.Bit, 0, 1, 0]
    bf.resize(8)
    doAssert bf == @[0.Bit, 0, 0, 0, 1, 0, 1, 0]
    bf.resize(4)
    doAssert bf == @[1.Bit, 0, 1, 0]
    bf.resize(0)
    doAssert bf == @[]
    bf.resize(1)
    doAssert bf == @[0.Bit]
  
  if size < bf.len:
    bf.delete(0..<bf.len - size.int)
  elif size > bf.len:
    bf.insert(newSeq[Bit](size - bf.len))

template resize*(bf: var BitField, typ: typedesc) =
  resize(bf, sizeof(typ) * 8)
  
#func fromBitfieldBigEndian*[T: typedesc(SomeUnsignedInt)](value: BitField): T =
#  ## Construct a big endian `SomeUnsignedInt` from `value`.
#  result = 0
#  for i, bit in value:
#    result = result or (T(bit) shl i)

## Indexes of on/true/1 bits
iterator bitsIdxOn*(value: BitField): int {.inline.} =
  for i, j in value:
    if j == 1:
      yield i

template bitsIdxOn*(value: SomeOrdinal): int =
  bitsIdxOn(value.toBitField)

func bitsIdxOnSeq*(value: BitField): seq[int] {.inline.} =
  bitsIdxOn(value).toSeq

template bitsIdxOnSeq*(value: SomeOrdinal): seq[int] =
  bitsIdxOnSeq(value.toBitField)

## Indexes of off/false/0 bits
iterator bitsIdxOff(value: BitField): int {.inline.} =
  for i, j in value:
    if j == 0:
      yield i

template bitsIdxOff*(value: SomeOrdinal): int =
  bitsIdxOff(value.toBitField)

func bitsIdxOffSeq*(value: BitField): seq[int] {.inline.} =
  bitsIdxOff(value).toSeq

template bitsIdxOffSeq*(value: SomeOrdinal): seq[int] =
  bitsIdxOffSeq(value.toBitField)

## Bitwise operations
func `and`*(a, b: BitField): BitField =
  ## Bitwise AND of `a` and `b`.
  assert a.len == b.len
  result = newSeq[Bit](a.len)
  for i in 0 ..< a.len:
    result[i] = a[i] and b[i]

func `and=`*(a: var BitField, b: BitField) =
  ## Bitwise AND of `a` and `b`.
  assert a.len == b.len
  for i in 0 ..< a.len:
    a[i] = a[i] and b[i]

func `or`*(a, b: BitField): BitField =
  ## Bitwise OR of `a` and `b`.
  assert a.len == b.len
  result = newSeq[Bit](a.len)
  for i in 0 ..< a.len:
    result[i] = a[i] or b[i]

func `or=`*(a: var BitField, b: BitField) =
  ## Bitwise OR of `a` and `b`.
  assert a.len == b.len
  for i in 0 ..< a.len:
    a[i] = a[i] or b[i]

func `xor`*(a, b: BitField): BitField =
  ## Bitwise XOR of `a` and `b`.
  assert a.len == b.len
  result = newSeq[Bit](a.len)
  for i in 0 ..< a.len:
    result[i] = a[i] xor b[i]

func `xor=`*(a: var BitField, b: BitField) =
  ## Bitwise XOR of `a` and `b`.
  assert a.len == b.len
  for i in 0 ..< a.len:
    a[i] = a[i] xor b[i]

func `not`*(a: BitField): BitField =
  ## Bitwise NOT of `a`.
  result = newSeq[Bit](a.len)
  for i in 0 ..< a.len:
    result[i] = 1 - a[i]

# Bit operations
func bitSet*(field: var BitField, pos: SomeInteger or BackwardsIndex, value: Bit) {.inline.} = 
  ## Set a `Bit` at position `pos` in `field`. In-place.
  ## Indexed from 0, most significant bit first.
  
  let p = field ^^ pos
  field[p] = value

proc bitSet*[U, V: Ordinal](field: var BitField, pos: HSlice[U,V], value: Bit) {.inline.} =
  let a = field ^^ pos.a
  let L = (field ^^ pos.b) - a + 1
  for i in 0..<L:
    field[i+a] = value

func bitFlip*(field: var BitField, pos: SomeInteger or BackwardsIndex) {.inline.} = 
  ## Flip a `Bit` at position `pos` in `field`. In-place.
  ## Indexed from 0, most significant bit first.
  runnableExamples:
    var bf: BitField = @[1.Bit, 0, 1, 0]
    bf.bitFlip(0)
    doAssert bf == @[0.Bit, 0, 1, 0]
    bf.bitFlip(3)
    doAssert bf == @[0.Bit, 0, 1, 1]
    doAssert bf.dup(bitFlip(3)) == @[0.Bit, 0, 1, 0] # Duplicates `bf` first and flips bit 3
    doAssert bf == @[0.Bit, 0, 1, 1] # Original `bf` is unchanged
  
  let p = field ^^ pos
  field[p] = not field[p]

func bitFlip*[U, V: Ordinal](field: var BitField, pos: HSlice[U,V]) {.inline.} = 
  let a = field ^^ pos.a
  let L = (field ^^ pos.b) - a + 1
  for i in 0..<L:
    field[i+a] = not field[i+a]