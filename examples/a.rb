
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

def ntp_test()
	# binding.pry
	$log.info "-"*30
	$log.info "Calibrating current time against NTP server:"
	Net::NTP.get("a.st1.ntp.br")

	#cache
	ntp = Net::NTP.get.time
	ntp = Net::NTP.get.time
	ntp = Net::NTP.get.time
	local = Time.now
	local = Time.now
	local = Time.now
	ntp = Net::NTP.get.time

	#run
	tot_diff = 0
	num = 5
	for i in 1..num do
		ntp = Net::NTP.get.time
		local = Time.now
		#$log.info "local= #{local.to_s}"
		#$log.info "ntp=   #{ntp.to_s}"
		diff = ntp.to_f-local.to_f
		#$log.info "diff = [%.6fs]" % [(diff)]
		tot_diff = tot_diff + diff
	end
	diff = tot_diff/num
	$log.info "diff_mean (num=%d) = [%.5fms]" % [ num, diff*1000]
	return diff
end

def binance_latence(rest, diff)
	$log.info "-"*30
	$log.info "Checking difference latecy to Binance server"
	tot_diff = 0
	num = 10
	for i in 1..num do
		bin_time = rest.time["serverTime"]
		s_local = Time.now
		s_local = s_local.to_f + diff
		bin_diff = s_local*1000-bin_time
		$log.info "[%.2fms]  %s  %s" % [(bin_diff), Time.at(s_local), Time.at(bin_time/1000) ]
		tot_diff = tot_diff + bin_diff
	end
	$log.info "diff_mean (num=%d) = [%.2fms]" % [ num, tot_diff/num ]
	return (tot_diff/num)/1000
end


rest  = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
ws    = Binance::Client::WebSocket.new


diff = 43.5
diff = 0
#diff = ntp_test
# pc certi
diff = -binance_latence(rest, diff)

$log.info "-"*30
$log.info "Polling binance:"

#
# listen_key = rest.listen_key
#  message = proc { |e| $log.info e.data }
#
#  EM.run do
#    ws.user_data listen_key: listen_key, methods: {message: message}
#  end

puts "Balance:"
puts rest.balance.inspect
puts rest.depth(symbol: 'BTCUSDT', limit: '5').inspect

client = ws
EM.run do
	# Create event handlers
	open    = proc { $log.info 'connected' }
	message = proc { |e|
		s_local = Time.now
		s_local = s_local.to_f + diff
		obj = JSON.parse(e.data)
		event_time = obj["data"]["E"]
		evt = (event_time.to_f/1000)
		evt = evt.to_f-evt.to_i
		trade_time = obj["data"]["T"]

		if obj["stream"]=="btcusdt@depth5" then
			#binding.pry
			message = "book : %.2f - %.2f" %
			[
				obj["data"]["bids"].first[0],
				obj["data"]["asks"].first[0]
			]
			$log.info message.yellow
		end

		if obj["stream"]=="btcusdt@aggTrade" then
			message = "%s (%.3fms) [%.2fms] : %.2f - %.6f" %
				[
					Time.at(event_time/1000).to_s,
					evt,
					(s_local*1000-event_time),
					obj["data"]["p"], #vl
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

				new_order( # evt vl qty
					(event_time/1000.0),
					obj["data"]["p"].to_f,
					(obj["data"]["m"] ? 1: -1) * obj["data"]["q"].to_f
				)
			end
		end
		#binding.pry

		# s_local_time = Time.at(s_local).to_s
		# s_event_time = Time.at(event_time/1000).to_s
		# s_trade_time = Time.at(trade_time/1000).to_s
		#$log.info  "#{s_local_time} : #{s_event_time} [%.2fms] : #{s_trade_time} :" % (s_local*1000-event_time)# + e.data
	}
	error   = proc { |e| $log.info e.inspect }
	close   = proc { $log.info 'closed' }

	# Bundle our event handlers into Hash
	methods = { open: open, message: message, error: error, close: close }

	# Pass a symbol and event handler Hash to connect and process events
	#client.agg_trade symbol: 'BTCUSDT', methods: methods
	# # kline takes an additional named parameter
	#client.kline symbol: 'BTCUSDT', interval: '1m', methods: methods
	# As well as partial_book_depth
	#client.partial_book_depth symbol: 'BTCUSDT', level: '5', methods: methods
	# Create a custom stream
	#client.single stream: { type: 'aggTrade', symbol: 'BTCUSDT'}, methods: methods

	# Create multiple streams in one call
	client.multi streams: [
					 { type: 'aggTrade', symbol: 'BTCUSDT' }#,
					 #{ type: 'ticker',   symbol: 'BTCUSDT' },
					 #{ type: 'kline',    symbol: 'BTCUSDT', interval: '1m'},
					 #{ type: 'depth',    symbol: 'BTCUSDT', level: '5'}
				 	],
					methods: methods
end
