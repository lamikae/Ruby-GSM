module GSM
  # To add new features, create a new Kermit script and add an alias or a method.
  class Terminal

    file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    this_dir = File.dirname(File.expand_path(file))
    @@scripts = File.join(this_dir,'kermit')

    # the data is intercepted from STDOUT
    STDOUT.sync = true
    STDERR.sync = true

    # checks the device status and enters the PIN if the SIM is locked.
    def initialize
    end

    # static methods
    class << self

    private

    # script parameter is the filename of the script
    def exec_kermit(script)
      dir = @@scripts
      executable = dir+'/'+script
      #logger.debug "Executing Kermit script %s" % script
      response = exec_command( 'cd %s && %s' % [ dir, executable ] )
      raise NoResponseException unless response
      return response
    end

    # simulate a response from the device
    def exec_test(script)
      # test directory echoes plain TXT files that fake response from the device
      dir = File.join(@@scripts,'test')
      executable = File.join(dir,script)

      # if the script does not exist (truncate parameters for checking), read the input from a file
      # (name constructed from script name + parameters)
      unless File.exists?(executable.split(' ')[0]) then
        response_fn = '/resp/'+script.gsub(/.sh.*/,'').gsub(/\ /,'_').downcase
        ##logger.debug "File %s does not exist, reading input from file %s" % [script, response_fn]
        return exec_command( 'cat %s' % dir+response_fn )
      else
        ##logger.debug "Executing shell script %s" % script
        return exec_command( 'cd %s && %s' % [ dir, executable] )
      end
    end

    # this does the actual I/O
    def exec_command( cmd )
      #logger.debug 'Executing system command "%s"' % cmd
      response = ''
      IO::popen( cmd ) do |f|
        until f.eof?
          # copy buffer
          response << f.gets
        end
      end
      ##logger.debug "Response: %s" % response
      raise NoInputException if response.empty?

      return response
    end

    def set_cmgf(encoding)
      if encoding==:ascii
        return 1
#       elsif encoding==:pdu
#         return 0
      else
        #logger.warn "Unsupported encoding #{encoding}, using ASCII"
        return 1
      end
    end

    def this_method
      caller[0][/`([^']*)'/, 1]
    end

    protected

    def raise_cms_error(response)
      error_code = response[/ERROR: (.*)/,1].to_i
      raise CMSError, 'CMS ERROR %i: %s' % [error_code, CMSError.message(error_code)]
    end

    def raise_cme_error(response)
      raise CMEError, response[/\+(.*ERROR.*)/,1]
    end

    def raise_general_error(response)
      msg = response[/ERROR: (.*)/,1]
      raise DeviceNotFoundException, msg if msg[/ttyUSB/]
      raise msg
    end

    public

    def method_missing(method, *args, &block) # :dodoc:
      #logger.debug "Creating dynamic method #{method}"
      $GSM_SIMULATION ||= false # perform the action on a real device (HAXK)
      if File.exists?(File.join(@@scripts,"#{method}.ksc"))
        return meta( args, method )
      end
    end

    # runs a Kermit script by the name of the alias of the method parameter.
    # returns true if the response is plain "OK".
    # otherwise returns an Array with the response section; the response(s) are between +COMMAND: ..... OK
    # the regexp for this is not perfect so it may or may not fail.
    def meta(params=nil,method=this_method)
      # select the script suffix on the basis whether
      # the device is present or are we simulating a response
      suffix = ($GSM_SIMULATION ? '.sh' : '.ksc')

      # use a script with the same name as the caller
      script = "#{method}"+suffix

      # add parameters, accept an Array or a single value
      params = [params] unless params.is_a? Array
      script << ' "' + params.join('" "') + '"' if params.any?

      # execute script
      if $GSM_SIMULATION
        response = exec_test(script)
      else
        response = exec_kermit(script)
      end

      # raise an error if the device outputs error
      raise_cme_error(response) if response[/CME\ ERROR/]
      raise_cms_error(response) if response[/CMS\ ERROR/]
      raise_general_error(response) if response[/ERROR/]

      # parse output
      responses = []
      #STDERR.puts 'Original: ' + response.inspect
      #STDERR.puts " ** "

      # clean the response; remove all strings (separated by newline) that start with AT but do NOT have ':'
      response.gsub!(/^AT[^:]*\n/,'')
      # remove BOOT and RSSI strings
      response.gsub!(/\^BOOT.*\n|\^RSSI.*\n/,'')

      #STDERR.puts 'Cleaned: ' + response.inspect
      #STDERR.puts " ** "

      response.split(/^\+|^AT.+\nOK|\^BOOT/).each_with_index do |output,index|
        unless output.nil?
          responses << output unless output.empty?
        end
      end

      return responses.compact || true
    end

    ########################################################
    ### Device status checks

    # sends plain AT to the modem, expecting OK
    # returns true if successful, false otherwise
    def device_responds?
      begin
        # send plain AT command
        meta(nil,:at)
      rescue DeviceNotFoundException
        false
      end
    end

    # checks if the PIN has been entered correctly and the device is ready
    def pin_ok?
      response = meta(nil,:check_pin).first
      response[/READY/] ? true : false
    end

    # returns true if there is a carrier, false otherwise
    def carrier?
      return false if self.carrier.nil?
      return false if self.carrier.empty?
      return true
    end


    ##########################################################
    ### Kermit script output parsers

    # outputs the device manufacturer, model and the GSM number (IMEI)
    def device_id
      response = meta(nil,:info).first
      manufacturer = response[/^Manufacturer: (.*)/,1].strip
      model = response[/^Model: (.*)/,1].strip
      revision = response[/^Revision: (.*)/,1].strip
      imei = response[/^IMEI: (.*)/,1].strip
      return '%s %s, IMEI: %s' % [manufacturer.capitalize,model,imei]
    end

    # gets the carrier string.
    # returns nil if carrier is not detected.
    def carrier
      response = meta(nil,this_method).first
      return response[/.,.,"([^"]*)"/,1]
    end

    # lists the available messages.
    #
    # parameters:
    #  1  CMGL filter: "ALL", "REC READ", "REC UNREAD", "STO SENT", "STO UNSENT"
    #  2  CMGF mode (PDU / ASCII)
    # NOTE: listing marks the SMS as 'READ'
    def list_sms(cmgl,encoding=:ascii)
      #logger.info "Listing %s messages" % cmgl
      cmgf=set_cmgf(encoding)
      messages = []
      meta([cmgl,cmgf],this_method).each_with_index do |msg,index|
        begin
          messages << SMS.new(msg, encoding)
        rescue SMSParseException
          #logger.error $!.message
        end
      end
      return messages
    end

    # reads a specific SMS
    # parameters:
    #  1  index
    #  2  CMGF mode (PDU / ASCII)
    def read_sms(index,encoding=:ascii)
      #logger.info "Reading message %i in %s mode" % [index, encoding.to_s]
      cmgf=set_cmgf(encoding)
      msg = meta([index,cmgf],this_method).first
      begin
        SMS.new(msg, encoding)
      rescue SMSParseException
        #logger.error $!.message
      end
    end

    ##########################################################
    ### Aliases that return parsed device response
    ### or raise CMSError or CMEError, see meta.

    public

    # sends the PIN number to unlock the SIM
    # parameters:
    #  1  PIN
    alias :enter_pin :meta

    # removes a specific SMS
    # parameters:
    #  1  index
    alias :del_sms   :meta

    # sends an ASCII-formatted SMS
    # parameters:
    #  1  GSM number (global, including +prefix)
    #  2  message
    alias :send_sms  :meta

    end # static methods

  end

  class DeviceNotFoundException < Exception
  end
  class NoInputException < Exception
  end

  class CMSError < Exception
    def self.message(code)
      case code
        when  300 then 'ME Failure'
        when  302 then 'Operation not allowed'
        when  303 then 'Operation not supported'
        when  304 then 'Invalid PDU mode parameter'
        when  305 then 'Invalid text mode parameter'
        when  320 then 'memory failure'
        when  321 then 'invalid memory index'
        when  322 then 'memory full'
        when  330 then 'SCA unknown'
        when  500 then 'Unknown error'
      end
    end
  end

  class CMEError < Exception
  end

end
