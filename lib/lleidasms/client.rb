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

    private
    def new_event(label, cmd, args)
    	@event_label = label
    	@event_cmd   = cmd
    	@event_args  = args
      if @wait_for_label.eql? @event_label
        @wait = false
      	@response_label = label
      	@response_cmd   = cmd
      	@response_args  = args
      end
    end

    def wait_for(label)
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
