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
require_relative 'lib/TradeExpert'
require_relative 'lib/TradePersistence'

# => https://pt.slideshare.net/autonomous/ruby-concurrency-and-eventmachine

def log_on()
	# -- rec trade
	$rec_file_name = "rec/TRADE_20191204_001437.dmp"
	# $rec_file_name = "rec/training_TRADE_20191204_001437.dmp"
	$rec_trade = PlayTrade.new( $rec_file_name )

	require_relative 'stdoutlog'
	# -- log monitor
	STDOUT.sync = true

	$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")

	$log_mon = StdoutLog.new($debug, LOG_MON_PREFIX + $timestamp + LOG_EXTENSION)
	$log_trade = StdoutLog.new($debug, LOG_TRADE_PREFIX + $timestamp + LOG_EXTENSION)
	$rec_trade = RecordTrade.new( REC_TRADE_PREFIX + $timestamp + REG_EXTENSION )
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

$log_mon.set_fileout_en( false )
$log_mon.set_stdout_en( false )
$log_trade.set_fileout_en( true )
$log_trade.set_stdout_en( false )


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
