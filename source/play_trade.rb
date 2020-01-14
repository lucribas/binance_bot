require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'
require 'ruby-prof'
require 'cli'

require_relative 'lib/defines'
require_relative 'lib/Logger'
require_relative 'lib/Utils'
require_relative 'lib/Trade'
require_relative 'lib/Account'


#---------------------------
# MAIN
#---------------------------

# Help
puts "="*120
puts "play_trade"
puts "="*120
puts "This code can:"
puts "- play recored tickets. (TradePersistence.rb)"
puts "- process tickets and generate signals and patterns. (TradeExpert.rb, Candle.rb, CandlestickPatterns.rb, CandlestickPatternsClassifier.rb)"
puts "- process signals and patterns with Bots. (CandleBot01.rb)"
puts "-"*120
# puts "how its works:"
# puts "-"*120
# puts "Instructions:"
# puts ""
puts ""
puts "-"*120
puts ""

# Check Command Line Arguments
$telegram_force_disabled = true

settings = CLI.new do
	description	"Tradener options"
	switch	:debug,		:short => :d,	:required => false,	:description => "Enables debug information"
	switch	:logger,	:short => :l,	:required => false,	:description => "Enables logger to file"
	switch	:sdtout,	:short => :s,	:required => false,	:description => "Enables output to screen"
	switch	:profiler,	:short => :p,	:required => false,	:description => "Enables profiler"
	switch	:telegram,	:short => :t,	:required => false,	:description => "Enables Telegram"
	option	:rec,		:short => :r,	:required => true,	:description => "Read the file name (#{REG_EXTENSION}) of record file with trades."
end.parse! do |settings|
	$debug						= true if !settings.debug.nil?
	$logger_en					= true if !settings.logger.nil?
	$sdtout_en					= true if !settings.sdtout.nil?
	$profiler_en				= true if !settings.profiler.nil?
	$telegram_force_disabled	= false if !settings.telegram.nil?
	$play_file_name				= settings.rec if !settings.rec.nil?
end


def log_init()
	# Logger
	# current timestamp
	$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")
	$log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: $logger_en, stdout_en: $sdtout_en)
	$log_trade = Logger.new( filename: LOG_TRADE_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: $logger_en, stdout_en: $sdtout_en)

	$td = Trade.new( log_mon: $log_mon, future_rest: nil )
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
