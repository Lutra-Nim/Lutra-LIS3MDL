## The LIS3MDL magnetometer, over I2C:
##
##   const compass = lis3mdl(i2c0)
##
##   i2c0.init(sda = IO18, scl = IO19)
##   compass.init(hz = 10)
##   let field = compass.read()
##
## It is run in its high-performance mode. Its thermometer and its interrupt
## are not covered.

import lutra/hal/i2c

type
  Lis3mdl*[B] = object
    bus*: B
    address*: byte
    gauss*: int
  Reading* = tuple[x, y, z: int32]

const
  # Registers
  whoAmI = 0x0F'u8
  control1 = 0x20'u8
  status = 0x27'u8
  outputs = 0x28'u8
  following = 0x80'u8 # Added to a register's number, to go on to the ones after it

func lis3mdl*[B](bus: B, address = 0x1C'u8, gauss = 4): Lis3mdl[B] =
  ## A sensor measuring up to `gauss` each way, which can be 4, 8, 12 or 16.
  ## The Earth's field is about half a gauss. Its address is 0x1C, or 0x1E
  ## with its address pin tied high.
  Lis3mdl[B](bus: bus, address: address, gauss: gauss)

proc init*[B: I2cBus](sensor: static Lis3mdl[B], hz: static int = 10): bool {.discardable.} =
  ## Starts it measuring `hz` times a second. False if no LIS3MDL answers.
  mixin write, writeRead
  const
    rate = [5, 10, 20, 40, 80].find(hz)
    scale = [4, 8, 12, 16].find(sensor.gauss)
  when rate < 0: {.error: "A LIS3MDL measures 5, 10, 20, 40 or 80 times a second.".}
  when scale < 0: {.error: "A LIS3MDL measures up to 4, 8, 12 or 16 gauss.".}
  var id: array[1, byte]
  if not sensor.bus.writeRead(sensor.address, [whoAmI], id) or id[0] != 0x3D: return false
  # Five registers in a row: the rate, with x and y at high performance; the
  # range; measuring continuously; z at high performance; and both bytes of a
  # reading held until both are read
  sensor.bus.write(sensor.address, [control1 or following,
    byte(0x40 or ((rate + 3) shl 2)), byte(scale shl 5), 0x00, 0x08, 0x40])
  true

proc ready*[B: I2cBus](sensor: static Lis3mdl[B]): bool =
  ## Whether there is a measurement that has not been read
  mixin writeRead
  var flags: array[1, byte]
  sensor.bus.writeRead(sensor.address, [status], flags) and (flags[0] and 0b1000) != 0

proc read*[B: I2cBus](sensor: static Lis3mdl[B]): Reading =
  ## The latest measurement, in thousandths of a gauss
  mixin writeRead
  const perGauss = int32([6842, 3421, 2281, 1711][[4, 8, 12, 16].find(sensor.gauss)]) # Steps
  var raw: array[6, byte]
  discard sensor.bus.writeRead(sensor.address, [outputs or following], raw)
  template axis(i: int): int32 =
    # Low byte first
    int32(cast[int16](raw[i].uint16 or (raw[i + 1].uint16 shl 8))) * 1000 div perGauss
  (axis(0), axis(2), axis(4))
