## Prints the magnetic field along each axis ten times a second, in
## thousandths of a gauss. The Earth's is a few hundred in all; a magnet
## brought near shows at once.
##
## Wire the sensor's SDA to IO18 and SCL to IO19, besides 3V3 and ground.

import lutra, lutra_lis3mdl

const compass = lis3mdl(i2c0)

i2c0.init(sda = IO18, scl = IO19)
if not compass.init(hz = 10): print "No LIS3MDL answers.\n"

while true:
  if compass.ready:
    let field = compass.read()
    print field.x, ",", field.y, ",", field.z, "\n"
