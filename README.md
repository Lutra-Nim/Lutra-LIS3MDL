# lutra_lis3mdl
### The LIS3MDL magnetometer, for Lutra

A driver for ST's LIS3MDL, written against [Lutra](https://github.com/garrettkinman/Lutra)'s `I2cBus` interface, so it runs on any board Lutra supports. Adafruit's [LSM6DS33 + LIS3MDL breakout](https://www.adafruit.com/product/4485) carries one; [lutra_lsm6ds33](https://github.com/garrettkinman/Lutra-LSM6DS33) drives the other half of that board.

```nim
import lutra, lutra_lis3mdl

const compass = lis3mdl(i2c0)

i2c0.init(sda = IO18, scl = IO19)
if not compass.init(hz = 10): print "No LIS3MDL answers.\n"

while true:
  if compass.ready:
    let field = compass.read()
    print field.x, ",", field.y, ",", field.z, "\n"
```

Readings are in thousandths of a gauss. The Earth's field is a few hundred in all, and a magnet brought near shows at once.

| | |
|---|---|
| `lis3mdl(bus, address = 0x1C, gauss = 4)` | A sensor on an I2C bus. The address is 0x1E with its address pin tied high. `gauss` is the most it measures each way: 4, 8, 12 or 16 |
| `compass.init(hz = 10)` | Starts it measuring 5, 10, 20, 40 or 80 times a second. False if no LIS3MDL answers |
| `compass.ready` | Whether there is a measurement not yet read |
| `compass.read()` | The latest measurement, as `(x, y, z)` |

The sensor runs in its high-performance mode. Its thermometer and its interrupt are not covered.

On Adafruit's breakout, wire VIN to 3V3, GND to ground, and SDA and SCL to any two free pins. Its other pins can stay unconnected.

The example in [examples/](examples) is run from that folder, with Lutra checked out beside this repository in a folder named `lutra`:

```
nim flash read.nim
nim monitor
```

`nim r tlis3mdl.nim` in [tests/](tests) checks the driver on the host, against a stand-in for the bus.
