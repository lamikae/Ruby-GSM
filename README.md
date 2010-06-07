This GSM Ruby library works on Linux, using a 3G device to send and receive SMS messages.

It uses Kermit to send AT commands to the device, and supports only ASCII character set.

The source code was written in 2008 and has been proprietary until released in 2010. Therefore it is not very flexible,
as for example there is no configuration file written in Ruby. Please set the modem device into `lib/kermit/kermrc`,
which by default is `/dev/ttyUSB1`.


