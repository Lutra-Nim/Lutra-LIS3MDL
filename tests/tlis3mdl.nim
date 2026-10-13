## The driver against a bus that is not there: what it writes, and what it
## makes of what it reads.

import lutra_lis3mdl

type Fake = object

var
  written: seq[seq[byte]]
  registers: array[256, byte]

proc write(bus: static Fake, address: byte, data: openArray[byte]): bool {.discardable.} =
  written.add @data
  address == 0x1C

proc read(bus: static Fake, address: byte, data: var openArray[byte]): bool = false

proc writeRead(bus: static Fake, address: byte, output: openArray[byte], input: var openArray[byte]): bool =
  for i in 0..<input.len: input[i] = registers[int(output[0] and 0x7f) + i]
  address == 0x1C

const
  compass = lis3mdl(Fake())
  wide = lis3mdl(Fake(), gauss = 16)
  absent = lis3mdl(Fake(), address = 0x1E)

doAssert not compass.init() # Nothing there says it is a LIS3MDL
doAssert written.len == 0
registers[0x0F] = 0x3D
doAssert not absent.init()
doAssert compass.init()
doAssert written == @[@[0xA0'u8, 0x50, 0x00, 0x00, 0x08, 0x40]]
written.setLen 0
doAssert wide.init(hz = 80)
doAssert written == @[@[0xA0'u8, 0x5C, 0x60, 0x00, 0x08, 0x40]]

doAssert not compass.ready
registers[0x27] = 0b1000
doAssert compass.ready

# One gauss along x at the narrowest range, the same the other way along y,
# and one step along z
registers[0x28..0x2D] = [0xBA'u8, 0x1A, 0x46, 0xE5, 0x01, 0x00]
doAssert compass.read() == (1000'i32, -1000'i32, 0'i32)
doAssert wide.read() == (3998'i32, -3998'i32, 0'i32)

doAssert not compiles(lis3mdl(Fake(), gauss = 2).init())
doAssert not compiles(compass.init(hz = 100))
doAssert not compiles(lis3mdl(42).init())
