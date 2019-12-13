require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'

$profiler_en = false

require 'ruby-prof' if $profiler_en

require_relative 'lib/defines'
require_relative 'lib/Logger'
require_relative 'lib/Utils'
require_relative 'lib/Trade'



def log_init()
	# -- rec trade
	$rec_file_name = "rec/TRADE_20191209_105843_snapshot.dmp"
	# $rec_file_name = "rec/training_TRADE_20191204_001437.dmp"
	$rec_trade = PlayTrade.new( $rec_file_name )

	# current timestamp
	$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")

	# Logger
	# $log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: false)
	$log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: false, stdout_en: false)
	$log_trade = Logger.new( filename: LOG_TRADE_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: false)

end

def read_all()
	n_trades = 0
	time_start = Time.now
	trade_obj = $rec_trade.read()
	log_start = trade_obj[:time]
	puts '-'*120
	while !trade_obj.nil? do
		n_trades += 1
		if ((n_trades % 10000)==0 ) then
			print sformat_time( trade_obj[:time] )+ "\r"
		end
		$stdout.flush
		# puts "recoved: " + trade_obj.inspect
		print_trade( trade_obj ) if $log_mon.log_en?
		update_candle( trade_obj )
		log_end = trade_obj[:time]
		trade_obj = $rec_trade.read()
	end
	time_end = Time.now
	puts '-'*120
	puts "log stared in %s and ended in %s -> %.2f hours" % [sformat_time(log_start), sformat_time(log_end), (log_end-log_start)/3600000]
	puts "total processed = #{n_trades} trades"
	puts "total time = %.2f s" % (time_end.to_f-time_start.to_f)
	puts "throughput = %.2f trades/s" % (n_trades/(time_end.to_f-time_start.to_f))
	puts '-'*120
	get_profit_report()
	puts '-'*120
end


# Create log infrastructure
log_init()


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
