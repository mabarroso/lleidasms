$:.unshift File.dirname(__FILE__)
require "gateway"

module Lleidasms
  class Client < Lleidasms::Gateway
		event :ALL, :new_event

    def connect(user, password)
    	super()
    	listener
      cmd_login(user, password)
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
      end
    end

    def wait_for(label)
      @wait_for_label = label.to_s
      @wait = true
    	while @wait do
        # sleep 0.1
    	end
    end

		def saldo(wait = true)
			cmd_saldo
			wait_for(last_label) if wait
			return @response_args[0]
		end


		def send_sms(wait = true)
			saldo
			wait_for(last_label) if wait
		end


  end
end
