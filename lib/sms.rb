module GSM

  # SMS text message
  class SMS
    attr_accessor :type
    attr_reader :index, :status, :gsmnr, :date, :time, :text

    # data might be PDU or ASCII.
    def initialize(data,type=:pdu)
      raise NoDataException unless data
      @data = data
      @date = _time = _index = nil
      if type == :ascii
        begin
          msgarray = data.split(/\r\n/)
          return nil unless msgarray.any?
          msgarray[0].split(',').each_with_index do |value,index|
            value.gsub!(/"/,'')
            case index
              when 0 then _index  = value
              when 1 then @status = value
              when 2 then @gsmnr  = value
              when 4 then @date   = value
              when 5 then _time   = value
            end
          end

          @index = _index[/(\d+)/,1].to_i
          @time = parse_time(@date,_time)
          @text = msgarray[1].gsub(/\r/,'') if msgarray[1]
        rescue
          raise SMSParseException, $!.message
        end

        # status should be set, otherwise this message is not acceptable
        raise SMSParseException unless @status

      elsif type == :pdu
        raise UnsupportedEncodingException, "PDU input is not handled!"
      end
    end

    def from
      @gsmnr
    end

    # self-generated SMS for testing
    # params:
    #  - :gsm
    #  - :content
    def self.testmsg(params)
      self.new(
        'CMGL: 17,"REC UNREAD","%s",,"08/08/21,16:07:27+12"' % params[:gsm] +"\r\n"+params[:content],
        :ascii)
    end

    def parse_time(date,time)
      x=date.split('/')+time.gsub(/\+..$/,'').split(':')
      Time.mktime(x[0],x[1],x[2],x[3],x[4],x[5])
    end

  end

  class NoDataException < Exception
  end

  class SMSParseException < Exception
  end

  class UnsupportedEncodingException < Exception
  end

end
