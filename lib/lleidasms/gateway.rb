require "thread"
require "socket"
require "io/wait"

module Lleidasms
  class Gateway
    # Client
    def initialize host = 'sms.lleida.net', port = 2048
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
        buffer.replace ''
      end
    end

    def connect
      begin
        $server = TCPSocket.new @host, @port
        $conected = true
      rescue
        $conected = false
        puts "Unable to open a connection."
        exit
      end
    end

    def listener
      Thread.new $server  do |socket|
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

     def self.event name, method_name
       $callbacks[name] = [] unless $callbacks[name]
      $callbacks[name] << method_name
    end

    def do_event name
      run_event name.to_sym, @label, @cmd, @args
    end

    def run_event name, *args
      run_event_for name.to_sym, self, *args
    end

    def run_event_for name, scope, *args
      return unless $callbacks[name.to_sym]
      $callbacks[name.to_sym].each do |callback|
        if callback.kind_of? Symbol
          scope.send callback, *args
        else
          scope.instance_exec *args, &callback
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

    def cmd_raw cmd, args, label_response = new_label
      $writer[label_response + " #{cmd} #{args}"]
    end

    # CMD Generales
    def cmd_login user, password, label_response = new_label
      $writer[label_response + " LOGIN #{user} #{password}"]
    end

    def cmd_ping time = Time.now.to_i.to_s, label_response = new_label
      $writer[label_response + " PING "+ time]
    end

    def cmd_pong time = Time.now.to_i.to_s, label_response = new_label
      $writer[label_response + " PONG "+ time]
    end

    def cmd_saldo label_response = new_label
      $writer[label_response + " SALDO"]
    end

    def cmd_infonum number, label_response = new_label
      $writer[label_response + " INFONUM #{number}"]
    end

    def cmd_tarifa number, label_response = new_label
      $writer[label_response + " TARIFA #{number}"]
    end

    def cmd_quit label_response = new_label
      $writer[label_response + " QUIT"]
    end
    # CMD Generales end

    # CMD Envios MT
    def cmd_submit number, message, label_response = new_label
      $writer[label_response + " SUBMIT #{number} #{message}"]
    end

    def cmd_bsubmit number, message, label_response = new_label
      $writer[label_response + " BSUBMIT #{number} #{message}"]
    end

    def cmd_usubmit number, message, label_response = new_label
      $writer[label_response + " USUBMIT #{number} #{message}"]
    end

    def cmd_fsubmit number, message, label_response = new_label
      $writer[label_response + " FSUBMIT #{number} #{message}"]
    end

    def cmd_fbsubmit number, message, label_response = new_label
      $writer[label_response + " FBSUBMIT #{number} #{message}"]
    end

    def cmd_fusubmit number, message, label_response = new_label
      $writer[label_response + " FUSUBMIT #{number} #{message}"]
    end

    def cmd_waplink number, message, label_response = new_label
      $writer[label_response + " WAPLINK #{number} #{message}"]
    end

    def cmd_dst numbers, label_response = new_label
      $writer[label_response + " DST #{numbers}"]
    end

    def cmd_msg message, label_response = new_label
      $writer[label_response + " MSG #{message}"]
    end

    #  *data* file contenten base64 encoded
    # Available types:
    #  * :jpeg        image JPEG
    #  * :gif         image GIF
    #  * :midi        polyfonic melody MIDI
    #  * :sp_midi     polyfonic melody SP-MIDI
    #  * :amr         sound AMR
    #  * :mp3         sound MP3
    #  * :gpp         video 3GP
    #  * :java        application JAVA
    #  * :symbian     application Symbian
    def cmd_filemsg type, data, label_response = new_label
      mime = mimetype type
      $writer[label_response + " FILEMSG #{mime} #{data}"] if mime
    end

    #  *data* file contenten base64 encoded
    #  *title* Information title before downloading content
    #  *message* Information text before downloading content
    # Available types:
    #  * :jpeg        image JPEG
    #  * :gif         image GIF
    #  * :midi        polyfonic melody MIDI
    #  * :sp_midi     polyfonic melody SP-MIDI
    #  * :amr         sound AMR
    #  * :mp3         sound MP3
    #  * :gpp         video 3GP
    #  * :java        application JAVA
    #  * :symbian     application Symbian
    def cmd_mmsmsg type, data, title, message, label_response = new_label
      mime = mimetype type
      $writer[label_response + " MMSMSG #{mime} #{data} #{title}|#{message}"] if mime
    end

    def cmd_envia label_response = new_label
      $writer[label_response + " ENVIA"]
    end
    # CMD Envios MT end

    # CMD Recepcion SMS (no premium)
    def cmd_allowanswer allow = true, label_response = new_label
      $writer[label_response + " ALLOWANSWER " + (allow ? 'ON' : 'OFF')]
    end

    def cmd_incomingmoack m_id, label_response = new_label
      $writer[label_response + " INCOMINGMOACK #{m_id}"]
    end

    # *opts*
    #   - cert: true/false (default false) use certificated confirmations
    #       * false (default)
    #       * :d Default Service
    #   - lang
    #       * :es Spanish (default)
    #       * :ca Catalan
    #       * :en English
    #       * :fr French
    #       * :de German
    #       * :it Italian
    #       * :nl Dutch
    #       * :pt Portuguese
    #       * :pl Polish
    #       * :se Swedish
    #   - mode
    #       * email to send notification
    #       * INTERNAL to use ACUSE
    def cmd_acuseon lang=false, cert=false, mode = 'INTERNAL', label_response = new_label
      l = lang ? "lang=#{lang.to_s.upcase} " : ''
      c = cert ? "cert_type=#{cert.to_s.upcase} " : ''
      $writer[label_response + " ACUSEON #{l}#{c}#{mode}"]
    end

    def cmd_acuseoff label_response = new_label
      $writer[label_response + " ACUSEOFF"]
    end

    # CMD Recepcion SMS (no premium) end

    # CMD Recepcion SMS (premium)
    # CMD Recepcion SMS (premium) end

    def parser
      until $input_buffer.empty?
        line = $input_buffer.shift
        puts ">#{line}\r\n"
        @args = line.split ' '
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
        when 'SUBMITOK'
        when 'BSUBMITOK'
        when 'USUBMITOK'
        when 'FSUBMITOK'
        when 'FBSUBMITOK'
        when 'FUSUBMITOK'
        when 'WAPLINKOK'
        when 'REJDST'

        # CMD Recepcion SMS (no premium)
        when 'INCOMINGMO'

        # CMD Recepcion SMS (premium)

        else
          # unknow
        end
        do_event @cmd
        do_event :all
      end
    end

    private
    def mimetype type
      case type
        when :jpeg
          'image/jpg'
        when :gif
          'image/gif'
        when :midi
          'audio/midi'
        when :sp_midi
          'audio/sp-midi'
        when :amr
          'audio/amr'
        when :mp3
          'audio/mpeg'
        when :gpp
          'video/3gpp'
        when :java
          'application/java-archive'
        when :symbian
          'application/vnd.symbian.instal'
        else
          false
      end
    end
  end
end
