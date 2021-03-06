#require 'em/pure_ruby'
require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'
require_relative 'stdoutlog'


require_relative 'secret_keys'

STDOUT.sync = true
$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")
$log_file_name = "log/TRADES_" + $timestamp + ".log"
$log = StdoutLog.new($debug, $log_file_name)


$orders = {}
def new_order(evt, vl, qty)
	# expires if > 120min
	if $orders.key?(-qty) and
		(evt-$orders[-qty][:evt]) > 120*60 then
		$orders.delete(-qty)
	end
	if $orders.key?(-qty) then
		#binding.pry
		$log.info "from %.2fs, closed %.6f order %.2f to %.2f with result of %.6f" % [ evt-$orders[-qty][:evt], qty, $orders[-qty][:vl], vl, qty * (vl-$orders[-qty][:vl]) ]
		$orders.delete(-qty)
	else
		$orders.delete(qty) if $orders.key?(qty)
		$orders[qty] = { :evt => evt, :vl => vl }
	end
end





# spot_rest  = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
# spot_ws    = Binance::Client::WebSocket.new

future_rest  = Binance::Client::REST_FUTURE.new api_key: api_key, secret_key: secret_key
future_ws    = Binance::Client::WebSocketFuture.new


diff = 43.5
diff = 0
#diff = ntp_test
# pc certi
#diff = -binance_latence(stop_rest, diff, 4)
diff = -binance_latence(future_rest, diff, 4)
$log.info "-"*30
$log.info "Polling binance:"
#
# listen_key = future_rest.listen_key
#  message = proc { |e| $log.info e.data }
#
#  EM.run do
#    future_ws.user_data listen_key: listen_key, methods: {message: message}
#  end

#puts "Normal Balance:"
#puts spot_rest.balance.inspect
puts "Future Balance:"
puts future_rest.balance.inspect

# puts "Normal depth:"
# puts spot_rest.depth(symbol: 'BTCUSDT', limit: '5').inspect
puts "Future depth:"
puts future_rest.depth(symbol: 'BTCUSDT', limit: '5').inspect


EM.run do
	# Create event handlers
	open    = proc { $log.info 'connected' }

	future_smessage = proc { |e|
		s_local = Time.now
		s_local = s_local.to_f + diff
		obj = JSON.parse(e.data)
		event_time = obj["data"]["E"]
		evt = (event_time.to_f/1000)
		evt = evt.to_f-evt.to_i
		trade_time = obj["data"]["T"]
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

	future_message = proc { |e|
		s_local = Time.now
		s_local = s_local.to_f + diff
		obj = JSON.parse(e.data)
		event_time = obj["data"]["E"]
		evt = (event_time.to_f/1000)
		evt = evt.to_f-evt.to_i
		trade_time = obj["data"]["T"]
		if obj["stream"]=="btcusdt@depth5" then
			#binding.pry
			message = "(future) book : (bid) %.2f - %.2f (ask)" %
			[
				obj["data"]["b"].first[0],  # specific for future
				obj["data"]["a"].first[0]  # specific for future
			]
			$log.info message.yellow
		end
		if obj["stream"]=="btcusdt@aggTrade" then
			message = "(future) %s (%.3fms) [%3.2fms] : %.2f (%s) - %.6f" %
			[
				Time.at(event_time/1000).to_s,
				evt,
				(s_local*1000-event_time),
				obj["data"]["p"], #vl
				obj["data"]["m"]?"bid":"ask",
				obj["data"]["q"] #qty
			]
			f_val = obj["data"]["q"].to_f
			if true then
				#if f_val>=0.002 then
				message = message + " " + "X"*f_val.to_i
				if obj["data"]["m"] then
					$log.info message.red
				else
					$log.info message.cyan
				end
				# new_order( # evt vl qty
				# 	(event_time/1000.0),
				# 	obj["data"]["p"].to_f,
				# 	(obj["data"]["m"] ? 1: -1) * obj["data"]["q"].to_f
				# )
			end
		end
	}



	spot_message = proc { |e|
		s_local = Time.now
		s_local = s_local.to_f + diff
		obj = JSON.parse(e.data)
		event_time = obj["data"]["E"]
		evt = (event_time.to_f/1000)
		evt = evt.to_f-evt.to_i
		trade_time = obj["data"]["T"]
		if obj["stream"]=="btcusdt@depth5" then
			#binding.pry
			message = "( spot ) book : (bid) %.2f - %.2f (ask)" %
			[
				obj["data"]["bids"].first[0],
				obj["data"]["asks"].first[0]
			]
			$log.info message.yellow
		end
		if obj["stream"]=="btcusdt@aggTrade" then
			message = "( spot ) %s (%.3fms) [%3.2fms] : %.2f (%s) - %.6f" %
			[
				Time.at(event_time/1000).to_s,
				evt,
				(s_local*1000-event_time),
				obj["data"]["p"], #vl
				obj["data"]["m"]?"bid":"ask",
				obj["data"]["q"] #qty
			]
			f_val = obj["data"]["q"].to_f
			if true then
				#if f_val>=0.002 then
				message = message + " " + "X"*f_val.to_i
				if obj["data"]["m"] then
					$log.info message.red
				else
					$log.info message.cyan
				end
				# new_order( # evt vl qty
				# 	(event_time/1000.0),
				# 	obj["data"]["p"].to_f,
				# 	(obj["data"]["m"] ? 1: -1) * obj["data"]["q"].to_f
				# )
			end
		end
	}
		#binding.pry
		# s_local_time = Time.at(s_local).to_s
		# s_event_time = Time.at(event_time/1000).to_s
		# s_trade_time = Time.at(trade_time/1000).to_s
		#$log.info  "#{s_local_time} : #{s_event_time} [%.2fms] : #{s_trade_time} :" % (s_local*1000-event_time)# + e.data


	error   = proc { |e| $log.info e.inspect }
	close   = proc { $log.info 'closed' }
	# Bundle our event handlers into Hash
	spot_methods = { open: open, message: spot_message, error: error, close: close }
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
	# spot_ws.multi streams: [
	# 	{ type: 'aggTrade', symbol: 'BTCUSDT' },
	# 	#{ type: 'ticker',   symbol: 'BTCUSDT' },
	# 	#{ type: 'kline',    symbol: 'BTCUSDT', interval: '1m'},
	# 	{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
	# ],
	# methods: spot_methods

	future_ws.multi streams: [
		#{ type: 'aggTrade', symbol: 'BTCUSDT' },
		#{ type: 'ticker',   symbol: 'BTCUSDT' },
		#{ type: 'kline',    symbol: 'BTCUSDT', interval: '1m'},
		{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
	],
	methods: future_methods

end
