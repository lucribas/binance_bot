
require 'em/pure_ruby'
require 'binance'
require 'eventmachine'


client = Binance::Client::WebSocket.new

# If you only plan on touching public API endpoints, you can forgo any arguments
 #client = Binance::Client::REST.new
# # Otherwise provide an api_key and secret_key as keyword arguments
# #client = Binance::Client::REST.new api_key: 'x', secret_key: 'y'
#
# # Ping the server
# puts client.ping # => {}
#
# for i in 1..3 do
# 	h = client.klines symbol: 'BTCUSDT', interval: '1m', limit: 1
# 	puts h.inspect
#
# end



EM.run do
  # Create event handlers
  open    = proc { puts 'connected' }
  message = proc { |e| puts e.data }
  error   = proc { |e| puts e }
  close   = proc { puts 'closed' }

  # Bundle our event handlers into Hash
  methods = { open: open, message: message, error: error, close: close }

  # Pass a symbol and event handler Hash to connect and process events
  client.agg_trade symbol: 'BTCUSDT', methods: methods
#
#   # kline takes an additional named parameter
  client.kline symbol: 'BTCUSDT', interval: '1m', methods: methods
#
#   # As well as partial_book_depth
#   client.partial_book_depth symbol: 'BTCUSDT', level: '5', methods: methods
#
#   # Create a custom stream
#   client.single stream: { type: 'aggTrade', symbol: 'BTCUSDT'}, methods: methods
#
#   # Create multiple streams in one call
#   client.multi streams: [{ type: 'aggTrade', symbol: 'BTCUSDT' },
#                          { type: 'ticker', symbol: 'BTCUSDT' },
#                          { type: 'kline', symbol: 'BTCUSDT', interval: '1m'},
#                          { type: 'depth', symbol: 'BTCUSDT', level: '5'}],
#                methods: methods
end
