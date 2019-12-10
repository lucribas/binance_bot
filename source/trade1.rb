require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'

require_relative 'secret_keys'
require_relative 'expert'
require_relative 'candlestick_patterns'
require_relative 'record_trade'

# => https://pt.slideshare.net/autonomous/ruby-concurrency-and-eventmachine


require_relative 'stdoutlog'
STDOUT.sync = true
$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")
$log_file_name = "log/MON_" + $timestamp + ".log"
$log = StdoutLog.new($debug, $log_file_name)

$log_file_name = "log/TRADE_" + $timestamp + ".log"
$trade = StdoutLog.new($debug, $log_file_name)


$log.set_fileout_en( true )
$log.set_stdout_en( true )
$trade.set_fileout_en( false )
$trade.set_stdout_en( false )

$rec_file_name = "rec/TRADE_" + $timestamp + ".dmp"
$rec_trade = RecordTrade.new( $rec_file_name )

# windows: $ENV:RECORD_ONLY=1
# linux: export RECORD_ONLY=1
$record_only = ENV.include?("RECORD_ONLY")

$future_rest  = Binance::Client::REST_FUTURE.new api_key: $api_key, secret_key: $secret_key
$future_ws    = Binance::Client::WebSocketFuture.new

$listen_key = $future_rest.listenKey["listenKey"]
# binding.pry
puts "Listener Key = #{$listen_key}"


$diff = 0

$td = Trade.new()

EM.run do
	# Create event handlers
	open    = proc { $td.on_open()  }
	close   = proc { $td.on_close() }
	error   = proc { |e| $td.on_error(e) }

	ud_message = proc { |e|
		$s_local = Time.now
		obj = JSON.parse(e.data)
		if (!obj["e"].nil?) then
			$td.orderTradeUpdate(obj)	if obj["e"]=="ORDER_TRADE_UPDATE"
			$td.accountUpdate(obj)	if obj["e"]=="ACCOUNT_UPDATE"
		end
		#binding.pry
	}

	ws_message = proc { |e|
		$s_local = Time.now
		obj = JSON.parse(e.data)
		if (!obj["stream"].nil?) then
			$td.btcusdt_depth5(obj) 		if obj["stream"]=="btcusdt@depth5"
			$td.new_btcusdt_aggTrade(obj)	if obj["stream"]=="btcusdt@aggTrade"
		end
	}

	# Bundle our event handlers into Hash
	ud_methods = { open: open, message: ud_message, error: error, close: close }

	ws_methods = { open: open, message: ws_message, error: error, close: close }

	#$future_ws.user_data  listen_key: listen_key, methods: ud_methods

	$future_ws.multi streams: [
		{ type: 'aggTrade', symbol: 'BTCUSDT' }
		# 	#{ type: 'ticker',   symbol: 'BTCUSDT' },
		# 	#{ type: 'kline',    symbol: 'BTCUSDT', interval: '1m'},
		# 	#{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
		#{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
		],
		methods: ws_methods


	#Keepalive a user data stream to prevent a time out. User data streams will close after 60 minutes. It's recommended to send a ping about every 30 minutes.
	EM.add_periodic_timer(25*60) {
		$log.info 'send keep_alive_stream!'
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
