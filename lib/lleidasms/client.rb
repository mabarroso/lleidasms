$:.unshift File.dirname(__FILE__)
require "gateway"

module Lleidasms
  class Client < Lleidasms::Gateway
    event :all, :new_event
    event :acuse, :new_acuse

    attr_accessor :timeout

    def connect user, password, timeout = 2.4
      super()
      listener
      cmd_login user, password
      self.timeout= timeout
      @acuse = []
    end

    def saldo
      cmd_saldo
      return false unless wait_for last_label
      return @response_args[0]
    end

    # *number*
    #   The telephone number
    def tarifa number
      cmd_tarifa number
      return false unless wait_for last_label
      return @response_args
    end

    # *number*
    #   The telephone number
    # *message*
    #   The string to send
    # *opts*
    #   - nowait: (default false) no wait for response
    #   - sender: The sender telephone number
    #   - date: Date and time to send message in format YYYYMMDDhhmm[+-]ZZzz
    #   - encode
    #       * :ascii (default)
    #       * :binary message is in base64 encoded
    #       * :base64 message is in base64 encoded
    #       * :unicode message is in unicode and base64 encoded
    def send_sms number, message, opts={}
      wait       =!(opts[:nowait] || false)
      encode    =  opts[:encode] || :ascii
      sender    =  opts[:sender] || false
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
        wait_for last_label
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
    def send_waplink number, url, message
      cmd_waplink number, url, message

      if wait
        wait_for last_label
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
    def add_addressee addressees, wait = true
      @addressees_accepted = false
      @addressees_rejected = false
      if addressees.kind_of?(Array)
        addressees = addressees.join ' '
      end

      cmd_dst addressees

      while wait && !@addressees_accepted
        wait_for last_label
        return false if !add_addressee_results
      end
    end

    def last_addressees_accepted
      return @addressees_accepted
    end

    def last_addressees_rejected
      return @addressees_rejected
    end

    # Set the message for the massive send list
    def msg message, wait = true
      cmd_msg message
      return false unless wait_for(last_label) if wait
      return @response_args
    end

    # Set file content (base64 encded) as message for the massive send list
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
    def filemsg type, data, wait = true
      cmd_filemsg type, data
      return false unless wait_for(last_label) if wait
      return @response_args
    end

    # Set file content (base64 encded) as message for the massive send list
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
    def mmsmsg type, data, title, message, wait = true
      cmd_mmsmsg type, data, title, message
      return false unless wait_for(last_label) if wait
      return @response_args
    end

    # Send message/file to the massive send list
    def send_all wait = true
      cmd_envia

      if wait
        wait_for last_label
        return false if @response_cmd.eql? 'NOOK'
        return "#{@response_args[0]}.#{@response_args[1]}".to_f
      end
    end

    # *opts*
    #   - nowait: (default false) no wait for response
    #   - cert: true/false (default false) use certificated confirmations
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
    def acuseon opts={}
      wait      =!(opts[:nowait]  || false)
      lang      =  opts[:lang]    || false
      cert      =  opts[:cert]    || false
      email     =  opts[:email]   || 'INTERNAL'

      cmd_acuseon lang, cert ? 'D' : false, email

      return false unless wait_for(last_label) if wait
      true
    end

    def acuseoff wait = true
      cmd_acuseoff
      return false unless wait_for(last_label) if wait
      true
    end

    def acuse?
      @acuse.count > 0
    end

    # Return hash or false
    #   - :id
    #   - :destino
    #   - :timestamp_acuse
    #   - :estado
    #       * :acked     Entregado a la operadora correctamente
    #       * :buffred   Telefono apagado o fuera de cobertura
    #       * :failed    El mensaje no se puede entregar en destino
    #       * :delivrd   El mesaje ha sido entregado en destino
    #   - :timestamp_envio
    #   - :texto
    def acuse
      return false unless acuse?
      row = @acuse.shift
      return {
          id: row[0],
          destino: row[1],
          timestamp_acuse: row[2],
          estado: row[3].to_sym,
          timestamp_envio: row[4],
          texto: row[5] || ''
        }
    end

    # - wait: (default false) no wait for response
    # - action
    #     * :begin
    #     * :end
    #     * :abort
    def trans action, wait = true
      return false unless cmd_trans action
      if wait
        wait_for last_label
        return false if @response_cmd.eql? 'NOOK'
        return false if @response_args[1].eql? 'NOOK'
        return true if @response_args[0].eql? 'INICIAR'
        return true if @response_args[0].eql? 'ABORTAR'
        return "#{@response_args[2]}.#{@response_args[3]}".to_f
      end
    end

    def trans_begin wait = true
      trans :begin, wait
    end

    def trans_end wait = true
      trans :end, wait
    end

    def trans_abort wait = true
      trans :abort, wait
    end

    private
    def add_addressee_results
      @addressees_rejected = @response_cmd_hash['REJDST'] if @response_cmd_hash['REJDST']
      @addressees_accepted = @response_cmd_hash['OK'] if @response_cmd_hash['OK']
      return false if @response_cmd.eql? 'NOOK'
      return true
    end

    def new_event label, cmd, args
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

    def wait_for label
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

    def new_acuse label, cmd, args
      @acuse << args
      cmd_acuseack args[0]
    end
  end
end
