require 'test/unit'
require 'init'
require 'test/test_environment'

class SMSTest < Test::Unit::TestCase
  def setup
    @msg = GSM::SMS.testmsg(:gsm => '+3584512345678', :content => 'the message')
  end

  def test_index
    assert_equal 17, @msg.index
  end

  def test_time
    assert_equal Time, @msg.time.class
  end

end
