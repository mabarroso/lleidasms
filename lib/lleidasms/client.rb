require "thread"
require "socket"
require "io/wait"

module Lleidasms
  module Client
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

		def parser
			until $input_buffer.empty?
				line = $input_buffer.shift
				puts ">#{line}\r\n"
			end
    end

  end
end
