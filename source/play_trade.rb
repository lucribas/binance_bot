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
require_relative 'lib/Account'


def log_init()
	# -- rec trade
	$play_file_name = "rec/TRADE_20191209_105843_snapshot.dmp"
	$play_file_name = "rec/TRADE_20191204_001437.dmp"

	# Logger
	# current timestamp
	$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")
	# $log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: false)
	$log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: false, stdout_en: false)
	$log_trade = Logger.new( filename: LOG_TRADE_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: false)

	$td = Trade.new( log_mon: $log_mon )
	$ac = Account.new()
end

# Create log infrastructure
log_init()

if $profiler_en then
	# profile the code
	RubyProf.start
end

# Main code
$td.read_all( file_name: $play_file_name )

if $profiler_en then
	# ... code to profile ...
	result = RubyProf.stop

	# print a flat profile to text
	printer = RubyProf::FlatPrinter.new(result)
	printer.print(STDOUT)
end
