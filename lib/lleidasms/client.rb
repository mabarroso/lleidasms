$:.unshift File.dirname(__FILE__)
require "gateway"

module Lleidasms
  class Client < Lleidasms::Gateway
		event :ALL, :new_event

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

		def tarifa(numero)
			cmd_tarifa numero
			return false unless wait_for(last_label)
			return @response_args
		end

		def send_sms(wait = true)
			saldo
			wait_for(last_label) if wait
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
