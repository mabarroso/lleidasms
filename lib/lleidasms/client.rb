$:.unshift File.dirname(__FILE__)
require "gateway"

module Lleidasms
  class Client < Lleidasms::Gateway
		event :all, :new_event

    attr_accessor :timeout

    def connect(user, password, timeout = 2.4)
    	super()
    	listener
      cmd_login(user, password)
      self.timeout= timeout
    end

		def saldo()
			cmd_saldo
			return false unless wait_for(last_label)
			return @response_args[0]
		end

    # *number*
    #   The telephone number
		def tarifa(number)
			cmd_tarifa number
			return false unless wait_for(last_label)
			return @response_args
		end

    # *number*
    #   The telephone number
    # *message*
    #   The string to send
    # *opts*
    #   - wait: (default true) wait for response
    #   - sender: The sender telephone number
    #   - date: Date and time to send message in format YYYYMMDDhhmm[+-]ZZzz
    #   - encode
    #       * :ascii (default)
    #       * :binary message is in base64 encoded
    #       * :base64 message is in base64 encoded
    #       * :unicode message is in unicode and base64 encoded
		def send_sms(number, message, opts={})
			wait   	  =!(opts[:nowait] || false)
			encode	  =  opts[:encode] || :ascii
			sender	  =  opts[:sender] || false
			datetime  =  opts[:date]   || false

			case encode
				when :binary || :base64
					encode = 'B'
				when :unicode
					encode = 'U'
				else # :ascii
			  	encode = ''
			end

			if sender
			  sender = "#{sender} "
			  custom = 'F'
			else
			  custom = ''
			end

			if datetime
			  datetime = "#{datetime} "
			  date = 'D'
			else
			  date = ''
			end

      cmd_raw "#{date}#{custom}#{encode}SUBMIT", "#{datetime}#{sender}#{number} #{message}"

			if wait
				wait_for(last_label)
				return false if @response_cmd.eql? 'NOOK'
				return "#{@response_args[0]}.#{@response_args[1]}".to_f
			end
		end

    # *number*
    #   The telephone number
    # *url*
    #   The URL to content. Usually a image, tone or application
    # *message*
    #   Information text before downloading content
		def send_waplink(number, url, message)
      cmd_waplink number, url, message

			if wait
				wait_for(last_label)
				return false if @response_cmd.eql? 'NOOK'
				return "#{@response_args[0]}.#{@response_args[1]}".to_f
			end
		end

    # Add telephone numbers into the massive send list.
    # It is recommended not to send more than 50 in each call
    #
    # Return TRUE if ok
    #   - see accepted in *last_addressees_accepted*
    #   - see rejected in *last_addressees_rejected*
		def add_addressee(addressees, wait = true)
		  @addressees_accepted = false
		  @addressees_rejected = false
      if addressees.kind_of?(Array)
        addressees = addressees.join(' ')
      end

      cmd_dst addressees

      while wait && !@addressees_accepted
        wait_for(last_label)
        return false if !add_addressee_results()
      end
		end

    def last_addressees_accepted
      return @addressees_accepted
    end

    def last_addressees_rejected
      return @addressees_rejected
    end

    # Set the message for the massive send list
		def msg(message, wait = true)
			cmd_msg message
			return false unless wait_for(last_label) if wait
			return @response_args
		end

    # Set file content (base64 encded) as message for the massive send list
    # Usually MIDI, MP3, AMR and java files
    # Available types:
    #  * :jpeg				image JPEG
    #  * :gif					image GIF
    #  * :midi				polyfonic melody MIDI
    #  * :sp_midi			polyfonic melody SP-MIDI
    #  * :amr					sound AMR
    #  * :mp3					sound MP3
    #  * :gpp					video 3GP
    #  * :java				application JAVA
    #  * :symbian			application Symbian
		def filemsg(type, message, wait = true)
			cmd_filemsg type, message
			return false unless wait_for(last_label) if wait
			return @response_args
		end

    private
    def add_addressee_results()
      @addressees_rejected = @response_cmd_hash['REJDST'] if @response_cmd_hash['REJDST']
      @addressees_accepted = @response_cmd_hash['OK'] if @response_cmd_hash['OK']
      return false if @response_cmd.eql? 'NOOK'
      return true
    end

    def new_event(label, cmd, args)
    	@event_label = label
    	@event_cmd   = cmd
    	@event_args  = args
      if @wait_for_label.eql? @event_label
        @wait = false
      	@response_label = label
      	@response_cmd   = cmd
      	@response_args  = args
      	@response_cmd_hash[cmd] = args
      end
    end

    def wait_for(label)
      @response_cmd_hash = {}
      @wait_for_label = label.to_s
      @wait = true
      t = Time.new
    	while @wait do
         sleep 0.2
         return false if @timeout < (Time.new - t)
    	end
    	return true
    end

  end
end
