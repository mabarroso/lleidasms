# Lleidasms
A [Lleida.net](http://lleida.net/) SMS gateway for Ruby.

# Description
Receive and send standar and premium SMS/MMS using [Lleida.net](http://lleida.net/) services.

##Features
  - client class
  - gateway superclass for new client implementations
##Protocol implementation (15%)
  - Comandos Generales (100%)
  	* implemented: saldo, ping, pong, infonum, tarifa, quit.
  - Comandos para el envíıo de MT simples (0%)
  	* implemented: none
  	* TODO: submit, bsubmit, usubmit, fsubmit, fbsubmit, fusubmit, dsubmit, dbsubmit, dusubmit, dfsubmit, dbfsubmit, dfusubmit, waplink, dst, msg, filemsg, mmsmsg, envia, acuseon, acuseoff, acuse, acuseack, trans.
  - Comandos para la recepcion de SMS (NO Premium) (0%)
  	* implemented: none
  	* TODO: allowanswer, incomingmo, incomingmoack.
  - Comandos para la recepcion de SMS (Premium) (0%)
  	* implemented: none
  	* TODO: deliver, resp, bresp, waplinkresp.
  - Comandos para la resolucion de MSIDSN (0%)
  	* implemented: none
  	* TODO: checkall, rcheckall, checknetwork, rchecknetwork.

#Installation
##From the command line.

```shell
  gem install lleidasms
```

##Using Gemfile.

1 Add to your application Gemfile

```ruby
gem 'lleidasms'
```

2 Type

```shell
  bundle install
```

# Examples
## Demo
```shell
  lleidasms YOUR_USER YOUR_PASSWORD
```

or

```shell
  lleidasms_client YOUR_USER YOUR_PASSWORD
```

## Using default client class
```ruby
  sms = Lleidasms::Client.new
  sms.connect <YOUR_USER>, <YOUR_PASSWORD>
  puts sms.saldo
  sms.close
```

## Creating a new client
```ruby
	class SMS < Lleidasms::Gateway
	  event :INCOMINGMO, :new_sms

	  def new_sms label, cmd, args
	    id    = args.shift
	    time  = args.shift
	    from  = args.shift
	    to    = args.shift
	    sms   = args.join(' ')
	    puts "  id #{id}"
	    puts "  time #{time}"
	    puts "  from #{from}"
	    puts "  to #{to}"
	    puts "  sms #{sms}"
	    cmd_incomingmoack id, label
	  end
	end

	sms = SMS.new
	sms.connect
	sms.listener
	sms.cmd_login <YOUR_USER>, <YOUR_PASSWORD>

	while sms.conected?
		# Some tasks
	end
```

# License
Released under the MIT license: [http://www.opensource.org/licenses/MIT](http://www.opensource.org/licenses/MIT)
