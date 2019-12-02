

require 'em/pure_ruby'
require 'binance'

# If you only plan on touching public API endpoints, you can forgo any arguments
client = Binance::Client::REST.new
# Otherwise provide an api_key and secret_key as keyword arguments
#client = Binance::Client::REST.new api_key: 'x', secret_key: 'y'

# Ping the server
puts client.ping # => {}

for i in 1..3 do
	h = client.klines symbol: 'BTCUSDT', interval: '1m', limit: 1
	puts h.inspect

end
