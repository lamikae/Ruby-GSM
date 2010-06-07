This GSM Ruby library uses a 3G device to send and receive SMS messages.

Check out Adam McKaig's [rubygsm](http://github.com/adammck/rubygsm) for another similar package that uses Ruby's native terminal interface.

This package uses Kermit to send AT commands to the device, and supports only ASCII character set.
Download Kermit from [here](http://www.columbia.edu/kermit/ck80.html#download).

The source code was written in 2008 and has been proprietary until released in 2010. Therefore it is not very flexible,
as for example there is no configuration file written in Ruby. Please set the modem device into `lib/kermit/kermrc`,
which by default is `/dev/ttyUSB1`.

This was developed by using Huawei E220 modem, but in theory any GSM device that has a terminal interface should work.

Example of how it is used:
<code>
    require 'Ruby-GSM'

    PIN='0000'

    begin
      unless GSM::Terminal.pin_ok?
        GSM::Terminal.enter_pin(PIN)
        sleep 15
      end

      GSM::Connection.check
	  puts GSM::Terminal.carrier

      # fetch new messages
      new_messages = GSM::Terminal.list_sms 'REC UNREAD'

      # send a new message
      GSM::Terminal.send_sms(['358451234567', 'message text'])

      # delete message number 3
      GSM::Terminal.del_sms 3
    end
</code>

For a list of other commands, refer to the source code ;)

