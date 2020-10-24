

require 'colorize'
require 'telegram/bot'

require_relative 'defines'

class Logger
	MAX_COLUMNS	= 100
	MAX_MESSAGE	= 60
	MAX_STATUS	= 10

	def initialize( debug: false, filename: nil, fileout_en: true, stdout_en: false )
		@debug_info = debug
		@file = nil
		@filename_int = filename
		@stdout_en = stdout_en
		@fileout_en = fileout_en
		@log_en = @stdout_en || @fileout_en
		STDOUT.sync = true

		if !filename.nil? && filename != "" then
			directory_name = File.dirname(filename)
			Dir.mkdir(directory_name) unless File.exists?(directory_name)
			@file = File.new(filename,  "w")
			info "Created logfile: #{filename}"
		end
		telegram_init()
	end

	def close()
		puts "Closing logfile: #{@filename_int}"
		@file.close if !@file.nil?
		@file = nil
	end


	def set_debug_info( debug_info )
		@debug_info = debug_info
	end

	def set_fileout_en( fileout_en )
		@fileout_en = fileout_en
		@log_en = @stdout_en || @fileout_en
	end

	def set_stdout_en( stdout_en )
		@stdout_en = stdout_en
		@log_en = @stdout_en || @fileout_en
	end

	def log_en?()
		return @log_en
	end

	def timestamp()
		time = Time.new
		return time.strftime("%Y-%m-%d %H:%M:%S")
	end

	def none( prefix, msg)
		message = prefix + "\t" + msg
		if (!message.nil? && message != "") then
			$stdout.puts message if @stdout_en
			@file.puts message if (@fileout_en && !@file.nil?)
			# message.each_line { |line|
			# 	$stdout.puts line if @stdout_en
			# 	@file.puts line if (@fileout_en && !@file.nil?)
			# }
			$stdout.flush if @stdout_en
			@file.flush if (@fileout_en && !@file.nil?)
		end	end

	def tradeinfo( message )
		now = timestamp()
		none( "|#{now}|INFO:  ", message.colorize(:default).on_cyan)
	end

	def trade( message )
		now = timestamp()
		none( "|#{now}|INFO:  ", message.on_black)
	end

	def info( message )
		now = timestamp()
		none( "|#{now}|INFO:  ", message.colorize(:default).on_magenta)
	end

	def debug( message )
		now = timestamp()
		none( "|#{now}|DEBUG:  ", message)
	end

	def error( message )
		now = timestamp()
		none( "|#{now}|ERROR:  ", message.magenta)
	end




		def sent_telegram( message )
			Telegram::Bot::Client.run($telegram_token) do |bot|
				bot.api.send_message( chat_id: 43716964, text: message)
			end
		end


		def telegram_init()
			begin
				$telegram_en = ((!ENV.include?("TELEGRAM_DISABLE")) && (!$telegram_force_disabled) )
				puts "telegram_en: #{$telegram_en}"
				sent_telegram( "connected!" ) if $telegram_en
			rescue StandardError => e
				puts "Telegram error:"
				puts "\n\t# to disable Telegram:"
				puts "\twindows:> $env:TELEGRAM_DISABLE=1"
				raise e
			end
		end

		private :timestamp
end



$message_buffer = ""

def send_trade_info( message )
	$message_buffer = $message_buffer + message + "\n"
end

def send_trade_info_send
	$log_trade.tradeinfo $message_buffer
	# puts "-->#{$message_buffer}<--"
	Logger.sent_telegram $message_buffer if $telegram_en
	$message_buffer = ""
end




def format_time( evt_time )
	evt = (evt_time.to_f/1000)
	evt = evt.to_f-evt.to_i
	return "%s (%.3fms)" %
	[	Time.at(evt_time/1000).to_s,
		evt	]
end



def sformat_time( evt_time )
	return Time.at(evt_time/1000).to_s
end



def print_trade( trade_obj )
	return if !$log_mon.log_en?
	event_time	= trade_obj[:event]
	trade_time	= trade_obj[:time]
	bull		= trade_obj[:bull]
	message		= " %s -> %s [%3.2fms] : %.2f (%s) - %.6f" %
	[
		format_time( event_time ),
		format_time( trade_time ),
		(0.0),
		trade_obj[:price],
		bull ? "bid" : "ask",
		trade_obj[:qty]
	]
	f_val = trade_obj[:qty].to_f
	message = message + " " + "X"*f_val.to_i
	if bull then
		$log_mon.trade message.cyan
	else
		$log_mon.trade message.red
	end

end
