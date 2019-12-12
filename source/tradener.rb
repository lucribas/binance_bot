require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'

# telegram and binance keys
require_relative 'secret_keys'


require_relative 'lib/defines'
require_relative 'lib/Logger'
require_relative 'lib/Utils'
require_relative 'lib/Account'
require_relative 'lib/Trade'

# windows: $ENV:TRADE_EN=1
# linux: export TRADE_EN=1
# $env:TELEGRAM_DISABLE=1
# windows: $ENV:RECORD_ONLY=1
# linux: export RECORD_ONLY=1

# current timestamp
$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")

# Logger
$log_mon = Logger.new( filename: LOG_MON_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: true)
$log_trade = Logger.new( filename: LOG_TRADE_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: false, stdout_en: false)

# Persistence
$rec_trade = RecordTrade.new( REC_TRADE_PREFIX + $timestamp + REG_EXTENSION )

# Binance connection
$future_rest  = Binance::Client::REST_FUTURE.new api_key: $api_key, secret_key: $secret_key
$future_ws    = Binance::Client::WebSocketFuture.new
$listen_key = $future_rest.listenKey["listenKey"]
puts "Listener Key = #{$listen_key}"

$td = Trade.new()
$td.check_latency()

$ac = Account.new()
$ac.update()
#
# binding.pry
# exit


# => https://pt.slideshare.net/autonomous/ruby-concurrency-and-eventmachine
# => https://pt.slideshare.net/OmerGazit/ruby-underground-event-machine

EM.run do
	# Create common event handlers
	open    = proc { $td.on_open()  }
	close   = proc { $td.on_close() }
	error   = proc { |e| $td.on_error(e) }
	# WebSocket (streaming) event handler - user_data stream
	ud_message = proc { |e|
		$s_local = Time.now
		obj = JSON.parse(e.data)
		if (!obj["e"].nil?) then
			$td.orderTradeUpdate(obj)	if obj["e"]=="ORDER_TRADE_UPDATE"
			$td.accountUpdate(obj)	if obj["e"]=="ACCOUNT_UPDATE"
		end
		#binding.pry
	}
	# WebSocket (streaming) event handler - multi streams
	multi_message = proc { |e|
		$s_local = Time.now
		obj = JSON.parse(e.data)
		if (!obj["stream"].nil?) then
			$td.btcusdt_depth5(obj) 		if obj["stream"]=="btcusdt@depth5"
			$td.new_btcusdt_aggTrade(obj)	if obj["stream"]=="btcusdt@aggTrade"
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
