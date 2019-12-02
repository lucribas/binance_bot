require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'

require_relative 'secret_keys'


# => https://pt.slideshare.net/autonomous/ruby-concurrency-and-eventmachine

require_relative 'stdoutlog'
STDOUT.sync = true
$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")
$log_file_name = "log/MON_" + $timestamp + ".log"
$log = StdoutLog.new($debug, $log_file_name)

def format_time( evt_time )
	evt = (evt_time.to_f/1000)
	evt = evt.to_f-evt.to_i
	return "%s (%.3fms)" %
	[	Time.at(evt_time/1000).to_s,
		evt	]
end



future_rest  = Binance::Client::REST_FUTURE.new api_key: api_key, secret_key: secret_key
future_ws    = Binance::Client::WebSocketFuture.new

listen_key = future_rest.listenKey["listenKey"]
puts "Listener Key = #{listen_key}"

diff = 0



# quando FILLED
# {"e"=>"ORDER_TRADE_UPDATE",  		// "e" Event Type
#  "T"=>1575052059911,				// "T" Transaction Time
#  "E"=>1575052059920,				// "E" Event Time
#  "o"=>
#   {
	# "s"=>"BTCUSDT",					// "s"  Symbol
	# "c"=>"web_DExU2JS1aXEOAS3iWylx",	// "c"  Client Order Id
	# "S"=>"SELL",						// "S"  Side
	# "o"=>"MARKET",					// "o"  Order Type
	# "f"=>"GTC",						// "f"  Time in Force
	# "q"=>"0.010",						// "q"  Original Quantity
	# "p"=>"0.00",						// "p"  Price
	# "ap"=>"7744.75000",				// "ap  Average Price
	# "sp"=>"0.00",						// "sp  Stop Price
	# "x"=>"TRADE",						// "x"  Execution Type
	# "X"=>"FILLED",					// "X"  Order Status
	# "i"=>250903870,					// "i"  Order Id
	# "l"=>"0.010",						// "l"  Order Last Filled Quantity
	# "z"=>"0.010",						// "z"  Order Filled Accumulated Quantity
	# "L"=>"7744.75",					// "L"  Last Filled Price
	# "n"=>"0.01548949",				// "n"  Commission, will not push if no commission
	# "N"=>"USDT",						// "N"  Commission Asset, will not push if no commission
	# "T"=>1575052059911,				// "T"  Order Trade Time
	# "t"=>15917929,					// "t"  Trade Id
	# "b"=>"75.12000",					// "b"  Bids Notional
	# "a"=>"7.74967",					// "a"  Ask Notional
	# "m"=>false,						// "m"  Is this trade the maker side?
	# "R"=>true,						// "R"  Is this reduce only
	# "wt"=>"CONTRACT_PRICE",			// "wt  stop price working type
	# "ot"=>"MARKET"}}
	#

EM.run do
	# Create event handlers
	open    = proc { $log.info 'connected' }

	future_smessage = proc { |e|
		s_local = Time.now
		s_local = s_local.to_f + diff

		obj = JSON.parse(e.data)

		if (!obj["e"].nil?) and obj["e"]=="ORDER_TRADE_UPDATE" then
			event_time = obj["E"]
			trade_time = obj["T"]
			# puts obj.inspect
			message = "[%s] %s -> %s : %s %s at %s (%s)" %
			[
				obj["e"],
				format_time( event_time ),
				format_time( trade_time ),
				obj["o"]["S"], 		# S  Side
				obj["o"]["z"], 		# Order Filled Accumulated Quantity
				obj["o"]["ap"],		# ap Average Price
				obj["o"]["X"],		# X  Order Status
			]
			$log.info message.yellow
		end

		if (!obj["e"].nil?) and obj["e"]=="ACCOUNT_UPDATE" then
			event_time = obj["E"]
			trade_time = obj["T"]
			# puts obj.inspect
			obj["a"]["B"].each { |b|
				if b["a"]=="USDT" then
					message = "[%s] %s -> %s : %s: %s" %
					[
						obj["e"],
						format_time( event_time ),
						format_time( trade_time ),
						b["a"],
						b["wb"]
					]
					$log.info message.yellow
				end
			}
		end
		#binding.pry


		if obj["stream"]=="btcusdt@depth5" then
			#binding.pry
			message = "%s (%.3fms) : %.2f - %.2f" %
			[
				Time.at(event_time/1000).to_s,
				evt,
				obj["data"]["b"].first[0],  # specific for future
				obj["data"]["a"].first[0]  # specific for future
			]
			$log.info message.yellow
		end
	}



	error   = proc { |e| $log.info e.inspect }
	close   = proc { $log.info 'closed' }
	# Bundle our event handlers into Hash
	#spot_methods = { open: open, message: spot_message, error: error, close: close }
	#future_methods = { open: open, message: future_message, error: error, close: close }
	future_methods = { open: open, message: future_smessage, error: error, close: close }

	# Pass a symbol and event handler Hash to connect and process events
	#client.agg_trade symbol: 'BTCUSDT', methods: methods
	# # kline takes an additional named parameter
	#client.kline symbol: 'BTCUSDT', interval: '1m', methods: methods
	# As well as partial_book_depth
	#client.partial_book_depth symbol: 'BTCUSDT', level: '5', methods: methods
	# Create a custom stream
	#client.single stream: { type: 'aggTrade', symbol: 'BTCUSDT'}, methods: methods
	# Create multiple streams in one call


	future_ws.user_data  listen_key: listen_key, methods: future_methods

	# future_ws.multi streams: [
	# 	#{ type: 'aggTrade', symbol: 'BTCUSDT' },
	# 	#{ type: 'ticker',   symbol: 'BTCUSDT' },
	# 	#{ type: 'kline',    symbol: 'BTCUSDT', interval: '1m'},
	# 	#{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
	# 	#{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
	# ],
	# methods: future_methods

end
