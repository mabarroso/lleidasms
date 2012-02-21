require "thread"
require "socket"
require "io/wait"

module Lleidasms
  class Gateway
    # Client
    def initialize(host = 'sms.lleida.net', port = 2048)
      @host = host
      @port = port
      @my_label = 0

      # prepare global (scriptable) data
      $conected      = false
      $input_buffer  = Queue.new
      $output_buffer = String.new

      $reader      = lambda do |line|
      	$input_buffer << line.strip
      	parser
      end
      $writer      = lambda do |buffer|
      	$server.puts "#{buffer}\r\n"
      	puts "<#{buffer}\r\n"
      	buffer.replace("")
      end
    end

    def connect
      begin
      	$server = TCPSocket.new(@host, @port)
      	$conected = true
      rescue
        $conected = false
      	puts "Unable to open a connection."
      	exit
      end
    end

    def listener
      Thread.new($server) do |socket|
      	while line = socket.gets
      		$reader[line]
      	end
      	close!
      end
    end

    def conected?
      $conected
    end

    def close
      cmd_quit
    end

    def close!
      $server.close
      $conected = false
    end
    # Client end

    # Callbacks
    $callbacks = {}

 	  def self.event(name, method_name)
 	  	$callbacks[name] = [] unless $callbacks[name]
      $callbacks[name] << method_name
		end

		def do_event(name)
			run_event name.to_sym, @label, @cmd, @args
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
    # Callbacks end

    def new_label
      @my_label += 1
      @my_label.to_s
    end

    def last_label
      @my_label
    end

    # CMD Generales
    def cmd_login(user, password, label_response = new_label)
      $writer[label_response + " LOGIN #{user} #{password}"]
    end

    def cmd_ping(time = Time.now.to_i.to_s, label_response = new_label)
      $writer[label_response + " PING "+ time]
    end

    def cmd_pong(time = Time.now.to_i.to_s, label_response = new_label)
      $writer[label_response + " PONG "+ time]
    end

    def cmd_saldo(label_response = new_label)
      $writer[label_response + " SALDO"]
    end

    def cmd_infonum(numero, label_response = new_label)
      $writer[label_response + " INFONUM #{numero}"]
    end

    def cmd_tarifa(numero, label_response = new_label)
      $writer[label_response + " TARIFA #{numero}"]
    end

    def cmd_quit(label_response = new_label)
      $writer[label_response + " QUIT"]
    end
    # CMD Generales end

    # CMD Envios MT
    # CMD Envios MT end

    # CMD Recepcion SMS (no premium)
    def cmd_allowanswer(allow = true, label_response = new_label)
      $writer[label_response + " ALLOWANSWER " + (allow ? 'ON' : 'OFF')]
    end

    def cmd_incomingmoack(m_id, label_response = new_label)
      $writer[label_response + " INCOMINGMOACK #{m_id}"]
    end
    # CMD Recepcion SMS (no premium) end

    # CMD Recepcion SMS (premium)
    # CMD Recepcion SMS (premium) end

		def parser
			until $input_buffer.empty?
				line = $input_buffer.shift
				puts ">#{line}\r\n"
				@args = line.split(' ')
				@label = @args.shift
				@cmd   = @args.shift

				case @cmd
				# CMD Generales
				when 'OK'
				when 'NOOK'
				when 'RSALDO'
				when 'PING'
				  cmd_pong @args[0], @label
				when 'PONG'
				  cmd_ping @args[0], @label
				when 'RINFONUM'
				when 'RTARIFA'
				when 'BYE'
					close!
        # CMD Envios MT

        # CMD Recepcion SMS (no premium)
        when 'INCOMINGMO'

        # CMD Recepcion SMS (premium)

				else
          # unknow
				end
				do_event(@cmd)
				do_event(:all)
			end
		end
  end
end
