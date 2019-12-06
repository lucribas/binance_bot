require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'

$profiler_en = false
require 'ruby-prof' if $profiler_en


$play_trade = true


require_relative 'secret_keys'
require_relative 'expert'
require_relative 'candlestick_patterns'
require_relative 'record_trade'

# => https://pt.slideshare.net/autonomous/ruby-concurrency-and-eventmachine


def log_on()
	# -- rec trade
	$rec_file_name = "rec/TRADE_20191204_001437.dmp"
	# $rec_file_name = "rec/training_TRADE_20191204_001437.dmp"
	$rec_trade = PlayTrade.new( $rec_file_name )

	# -- log monitor
	require_relative 'stdoutlog'
	STDOUT.sync = true
	$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")
	$log_file_name = "log/MON_" + $timestamp + ".log"
	$log = StdoutLog.new($debug, $log_file_name)
	$log.set_fileout_en( false )
	$log.set_stdout_en( false )

	# -- log trade
	$td_file_name = "log/TRADE_" + $timestamp + ".log"
	$trade = StdoutLog.new($debug, $td_file_name)
	$trade.set_fileout_en( true )
	$trade.set_stdout_en( false )
end

def sformat_time( evt_time )
	return Time.at(evt_time/1000).to_s
end

def format_time( evt_time )
	evt = (evt_time.to_f/1000)
	evt = evt.to_f-evt.to_i
	return "%s (%.3fms)" %
	[	Time.at(evt_time/1000).to_s,
		evt	]
end

def print_trade( trade_obj )
	return if $log.log_en?
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
		$log.info message.cyan
	else
		$log.info message.red
	end
end

def read_all()
	n_trades = 0
	trade_obj = $rec_trade.read()
	while !trade_obj.nil? do
		n_trades = n_trades + 1
		if ((n_trades % 10000)==0 ) then
			print sformat_time( trade_obj[:time] )+ "\r"
		end
		$stdout.flush
		#puts "recoved: " + trade_obj.inspect
		# print_trade( trade_obj )
		update_candle( trade_obj )
		trade_obj = $rec_trade.read()
	end
	puts "total trades processed = #{n_trades}"
	get_profit_report()
end


# Create log infrastructure
log_on()

if $profiler_en then
	# profile the code
	RubyProf.start
end

# Main code
read_all()

if $profiler_en then
	# ... code to profile ...
	result = RubyProf.stop

	# print a flat profile to text
	printer = RubyProf::FlatPrinter.new(result)
	printer.print(STDOUT)
end
