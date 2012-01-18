module Lleidasms
  module Callbacks
    $callbacks = {}

 	  def event(name, method_name)
 	  	$callbacks[name] = [] unless $callbacks[name]
      $callbacks[name] << method_name
		end

		def run_event(name, *args)
      run_event_for(name.to_sym, self, *args)
    end

    def run_event_for(name, scope, *args)
    	return unless $callbacks[name.to_sym]
      $callbacks[name.to_sym].each do |callback|
        if callback.kind_of? Symbol
          scope.send(callback, *args)
        else
          scope.instance_exec(*args, &callback)
        end
      end
    end

  end
end