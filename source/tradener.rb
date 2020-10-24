require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'bigdecimal'
require 'cli'

# telegram and binance keys
require_relative 'secret_keys'

require_relative 'lib/defines'
require_relative 'lib/Logger'
require_relative 'lib/Utils'
require_relative 'lib/Account'
require_relative 'lib/Trade'

#---------------------------
# MAIN
#---------------------------

# Help
puts "="*120
puts "Tradener"
puts "="*120
puts "This code can:"
puts "- record all tickets of all trades from Binance. (TradePersistence.rb)"
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

# # Check Command Line Arguments
# settings = CLI.new do
# 	description	"Tradener options"
# 	switch	:debug,		:short => :d,	:required => false,	:description => "Enables debug information"
# 	switch	:cache,		:short => :c,	:required => false,	:description => "Enables cache"
# 	option	:r_csv_file,	:short => :r,	:required => false,	:description => "file name of cvs file with list of ReviewRecord items."
# end.parse! do |settings|
# 	$debug		= true if !settings.debug.nil?
# 	$cache_en	= true if !settings.cache.nil?
# 	$r_csv_file	= settings.r_csv_file if !settings.r_csv_file.nil?
# end



# TRADE_REC_DISABLE
# TRADE_REALTIME_DISABLE
# TRADE_TEST_MODE
# TELEGRAM_DISABLE
# example
# windows: $ENV:TELEGRAM_DISABLE=1
# linux: export TELEGRAM_DISABLE=1

# current timestamp
$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")

# Logger
$log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: true)
$log_trade = Logger.new( filename: LOG_TRADE_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: false, stdout_en: false)

# Persistence
$rec_trade = RecordTrade.new( REC_TRADE_PREFIX + $timestamp + REG_EXTENSION )

def open_binance()
	# Binance connection
	$future_rest  = Binance::Client::REST_FUTURE.new api_key: $api_key, secret_key: $secret_key
	$future_ws    = Binance::Client::WebSocketFuture.new
	$listen_key = $future_rest.listenKey["listenKey"]
	puts "Listener Key = #{$listen_key}"
end

open_binance()

# Utils.ntp_test()

$td = Trade.new( rec_trade: $rec_trade, future_rest: $future_rest, log_mon: $log_mon )
$td.check_latency()
$ac = Account.new()
$ac.update()
#
# binding.pry
# exit

# about eventmachine
# => https://pt.slideshare.net/autonomous/ruby-concurrency-and-eventmachine
# => https://pt.slideshare.net/OmerGazit/ruby-underground-event-machine

# activity watchdog
$wtg_trie = 0
$act_wtc = Time.now

EM.run do
	# Create common event handlers
	open    = proc { $td.on_open()  }
	close   = proc { $td.on_close() }
	error   = proc { |e| $td.on_error(e) }
	# WebSocket (streaming) event handler - user_data stream
	ud_message = proc { |e|
		$s_local = Time.now
# {'e': 'listenKeyExpired', 'E': 1576763248644}
		obj = nil
		begin
			obj = JSON.parse(e.data)
		rescue
			$log_mon.error obj.inspect
			open_binance()
		end
		if (!obj.nil? && !obj["e"].nil?) then
			$td.orderTradeUpdate(obj)	if obj["e"]=="ORDER_TRADE_UPDATE"
			$td.accountUpdate(obj)	if obj["e"]=="ACCOUNT_UPDATE"
			$act_wtc = Time.now
		end
		#binding.pry
	}
	# WebSocket (streaming) event handler - multi streams
	multi_message = proc { |e|
		$s_local = Time.now
		obj = nil
		begin
			obj = JSON.parse(e.data)
		rescue
			$log_mon.error obj.inspect
			open_binance()
		end
		if (!obj.nil? &&!obj["stream"].nil?) then
			$td.btcusdt_depth5(obj) 		if obj["stream"]=="btcusdt@depth5"
			$td.new_btcusdt_aggTrade(obj)	if obj["stream"]=="btcusdt@aggTrade"
			$act_wtc = Time.now
		end
	}

	# Bundle our event handlers into Hash
	ud_methods = { open: open, message: ud_message, error: error, close: close }
	# Register callbacks
	$future_ws.user_data  listen_key: $listen_key, methods: ud_methods

	# Bundle our event handlers into Hash
	multi_methods = { open: open, message: multi_message, error: error, close: close }
	# Register callbacks
	$future_ws.multi streams: [
		{ type: 'aggTrade', symbol: 'BTCUSDT' }
		# 	#{ type: 'ticker',   symbol: 'BTCUSDT' },
		# 	#{ type: 'kline',    symbol: 'BTCUSDT', interval: '1m'},
		# 	#{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
		#{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
		],
		methods: multi_methods


	#Keepalive a user data stream to prevent a time out. User data streams will close after 60 minutes. It's recommended to send a ping about every 30 minutes.
	EM.add_periodic_timer(25*60) {
		$log_mon.info 'send keep_alive_stream!'
		$future_rest.keep_alive_stream!
	}


	EM.add_periodic_timer(130) {
		# if more than 10min without bit
		if ((Time.now-$act_wtc)>120) then
			if ($wtg_trie>10) then
				$log_mon.error "Watchdog: exeeded try number. Exiting"
				exit(-1)
			end
			$log_mon.error "Watchdog: more than 2min without bit! (try=#{$wtg_trie}) Reopen connections.."
			open_binance()
			$wtg_trie = $wtg_trie + 1
		else
			$wtg_trie = 0
		end
	}


	# Pass a symbol && event handler Hash to connect && process events
	#client.agg_trade symbol: 'BTCUSDT', methods: methods
	# # kline takes an additional named parameter
	#client.kline symbol: 'BTCUSDT', interval: '1m', methods: methods
	# As well as partial_book_depth
	#client.partial_book_depth symbol: 'BTCUSDT', level: '5', methods: methods
	# Create a custom stream
	#client.single stream: { type: 'aggTrade', symbol: 'BTCUSDT'}, methods: methods
	# Create multiple streams in one call
end
