$:.unshift File.dirname(__FILE__)
require "callbacks"
require "client"

module Lleidasms
  class Gateway
    extend Callbacks

    # Client
    attr_accessor :host, :port

    def initialize(host = 'sms.lleida.net', port = 2048)
      @host = host
      @port = port
      @label = 0

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

    def conected?
      $conected
    end

    def connect
      begin
      	$server = TCPSocket.new(@host, @port)
      	$conected = true
      rescue
        $conected = false
      	puts "Unable to open a connection."
      end
    end

    def close!
      $server.close
      $conected = false
    end

    def listener
      Thread.new($server) do |socket|
      	while line = socket.gets
      		$reader[line]
      	end
      end
    end
    # Client end

    def close
      quit
    end

    def label
      @label += 1
      @label.to_s
    end

    # CMD Generales
    def login(user, password, label_response = label)
      $writer[label_response + " LOGIN #{user} #{password}"]
    end

    def ping(time = Time.now.to_i.to_s, label_response = label)
      $writer[label_response + " PING "+ time]
    end

    def pong(time = Time.now.to_i.to_s, label_response = label)
      $writer[label_response + " PONG "+ time]
    end

    def saldo(label_response = label)
      $writer[label_response + " SALDO"]
    end

    def infonum(numero, label_response = label)
      $writer[label_response + " INFONUM #{numero}"]
    end

    def tarifa(numero, label_response = label)
      $writer[label_response + " TARIFA #{numero}"]
    end

    def quit(label_response = label)
      $writer[label_response + " QUIT"]
    end

    # CMD Envios MT

    # CMD Recepcion SMS (no premium)
    def allowanswer(allow = true, label_response = label)
      $writer[label_response + " ALLOWANSWER " + (allow ? 'ON' : 'OFF')]
    end

    def incomingmoack(m_id, label_response = label)
      $writer[label_response + " INCOMINGMOACK #{m_id}"]
    end

    # CMD Recepcion SMS (premium)


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
				  pong @args[0], @label
				when 'PONG'
				  ping @args[0], @label
				when 'RINFONUM'
				when 'RTARIFA'
				when 'BYE'
					close!
        # CMD Envios MT

        # CMD Recepcion SMS (no premium)
        when 'INCOMINGMO'
        # CMD Recepcion SMS (premium)
				else
          #	CMD unknow
				end
				run_event(@cmd, @label, @cmd, @args)
				run_event(:ALL, @label, @cmd, @args)
			end
		end
  end
end
