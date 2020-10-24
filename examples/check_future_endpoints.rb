require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'
require_relative '../source/secret_keys'

# spot_rest  = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
# spot_ws    = Binance::Client::WebSocket.new
future_rest  = Binance::Client::REST_FUTURE.new api_key: $api_key, secret_key: $secret_key
future_ws    = Binance::Client::WebSocketFuture.new

# puts "-"*40
# puts "Future depth:"
# puts future_rest.depth(symbol: 'BTCUSDT', limit: '5').inspect
puts "-"*40
puts "test"

# binding.pry
Binance::Client::REST_FUTURE::ENDPOINTS.each_with_index do |(key, value), index|
	puts "-"*30
	print "key: #{key}, value: #{value}, index: #{index}\n"
	if future_rest.respond_to?(key) then
		res = future_rest.method(key).call
		if res.class == String and res.to_s.include?("cannot be found") then
			puts "\tnot found".red
		else
			puts res.inspect
		end
	else
		puts "\tmethod not respond directly"
	end
end
