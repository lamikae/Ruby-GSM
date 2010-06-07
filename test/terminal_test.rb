require 'test/unit'
require 'init'
require 'test/test_environment'

# the ENV variables are for the bash scripts

# Higher level tests for parsing Kermit output
class TerminalTest < Test::Unit::TestCase
  def test_device
    assert ::GSM::Terminal.device_responds?
  end

  # test the locked state only in simulation.
  # just assume that the actual device is already unlocked.
  def test_pin_ok
    if GSM_SIMULATION
      ENV['PIN_FAILURE']='true'
      assert !::GSM::Terminal.pin_ok?
      ENV['PIN_FAILURE']='false'
    end
    assert ::GSM::Terminal.pin_ok?
  end

  # entering the pin is tested only in simulation
  def test_enter_pin
    if GSM_SIMULATION
      ENV['WRONG_PIN']='true'
      assert_raise(::GSM::CMEError) { ::GSM::Terminal.enter_pin('1234') }
      ENV['WRONG_PIN']='false'
      assert ::GSM::Terminal.enter_pin('1234')
    end
  end

  # assume that the device has carrier.
  def test_carrier
    if GSM_SIMULATION
      ENV['NO_CARRIER']='true'
      assert !::GSM::Terminal.carrier?
      ENV['NO_CARRIER']='false'
    end
    assert ::GSM::Terminal.carrier?
  end

  # test the string only with test data, to compare that the response is parsed OK
  def test_carrier_string
    if GSM_SIMULATION
      ENV['NO_CARRIER']='false'
        assert ::GSM::Terminal.carrier=='FI elisa', 'Carrier string parse failure'
    end
  end

  def test_device_id
    assert ::GSM::Terminal.device_id
    assert_equal ::GSM::Terminal.device_id, 'Huawei E220, IMEI: 358451234567' if GSM_SIMULATION
  end

  def test_list_sms
    messages = ::GSM::Terminal.list_sms('ALL')
    if GSM_SIMULATION
      assert_equal  messages.size, 3
      messages = ::GSM::Terminal.list_sms('REC UNREAD')
      assert_equal messages.size, 2
    end
  end

  def test_list_sms_none
    if GSM_SIMULATION
      ENV['NO_UNREAD_MESSAGES']='true'
      messages = ::GSM::Terminal.list_sms('REC UNREAD')
      assert messages.size==0
    end
  end

  def test_read_failure
    if GSM_SIMULATION
      ENV['SMS_INVALID']='true'
      assert_raise(::GSM::CMSError) { ::GSM::Terminal.read_sms('1') }
    end
  end

  # test message 0 contains static data which should not change
  def test_ascii_sms_parsing
    ENV['SMS_INVALID']='false'
    msg = ::GSM::Terminal.read_sms(0)
    time = Time.mktime(2008,8,21,16,15,13)
    assert_not_nil msg, 'Device needs at least 1 SMS to test parsing'
    assert msg.index == 0, 'Index does not match'
    assert msg.status == 'REC READ'
    if GSM_SIMULATION
      assert_equal '15004', msg.gsmnr
      assert_equal 'This is an SMS message, which may or may not include the string OK. ', msg.text
      assert_equal '08/08/21', msg.date
      assert_equal time, msg.time
    end
  end

  def test_del_msg
    assert_nothing_raised { GSM::Terminal.del_sms(17) }
  end
end
