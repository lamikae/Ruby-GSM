module GSM
  class Connection
    class << self

    # check the pre-requisites for GSM operation
    def check
      raise PinRequestException unless Terminal.pin_ok?
      raise NoCarrierException  unless Terminal.carrier?
    end

    end
  end # Connection

  class PinRequestException < Exception
  end
  class NoCarrierException < Exception
  end
end