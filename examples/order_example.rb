require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'
require_relative 'stdoutlog'

require_relative 'secret_keys'


# spot_rest  = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
# spot_ws    = Binance::Client::WebSocket.new
future_rest  = Binance::Client::REST_FUTURE.new api_key: api_key, secret_key: secret_key
future_ws    = Binance::Client::WebSocketFuture.new
# puts "-"*40
# puts "Future depth:"
# puts future_rest.depth(symbol: 'BTCUSDT', limit: '5').inspect
puts "-"*40
puts "test"
# binding.pry
open = future_rest.open_orders symbol: 'BTCUSDT'
# all orders
all = future_rest.all_orders symbol: 'BTCUSDT'

binding.pry
exit(-1)

# "orderId"=>146612385,
#   "symbol"=>"BTCUSDT",
#   "status"=>"FILLED",
#   "clientOrderId"=>"web_fH5aqqyDFMXxhiWRh852",
#   "price"=>"0",
#   "origQty"=>"0.053",
#   "executedQty"=>"0.053",
#   "cumQuote"=>"481.12393",
#   "timeInForce"=>"GTC",
#   "type"=>"MARKET",
#   "reduceOnly"=>false,
#   "side"=>"BUY",
#   "stopPrice"=>"0",
#   "workingType"=>"CONTRACT_PRICE",
#   "origType"=>"MARKET",
#   "time"=>1573427687258,
#   "updateTime"=>1573427687291},
# all.each { |o|
# 	puts o["status"]
# 	FILLED
# 	CANCELED
# 	NEW
# 	puts o["origType"]
# 	LIMIT
# 	STOP
# 	STOP_MARKET
# 	MARKET
# 	TAKE_PROFIT
# 	puts o["origQty"]
# 	puts o["executedQty"]
# }
#res = future_rest.query_order
query = future_rest.query_order symbol: 'BTCUSDT', origclientOrderId: '7itt71O1wo8Y1emxwzxCGw'



loss = 10
quantity = 0.001
price = 7000

# confirm buy

query.each { |a|
#puts a["orderId"]
if a["orderId"] == 250608142 then puts a end
}

# -> listener para ticks
# - atualizar monitores
#
# -> listener para update de ordens
# - atualizar monitores
#
# -> dentro do ticker



#
# loss_trig_price = price - loss
# loss_price = price - loss - 10
# obuy 	 = push_buy(  		 quantity: quantity, price: price )
# monitor_filled( obuy )
# obuy_stp = push_buy_stop(   quantity: quantity, loss_trig_price: loss_trig_price, loss_price: loss_price )
#
#
# loss_trig_price = price + loss
# loss_price = price + loss + 10
# osell = push_sell( 		 quantity: quantity, price: price)
# monitor_filled( osell )
# osell_stp = push_sell_stop(  quantity: quantity, loss_trig_price: loss_trig_price, loss_price: loss_price)
#


# modo mais simples primeiro
# entrar a market
loss_trig_price = price - loss
loss_price = price - loss - 10
obuy 	 = push_buy(  		 quantity: quantity, price: 0 )
monitor_filled( obuy )
obuy_stp = push_buy_stop(   quantity: quantity, loss_trig_price: loss_trig_price, loss_price: loss_price )


loss_trig_price = price + loss
loss_price = price + loss + 10
osell = push_sell( 		 quantity: quantity, price: 0)
monitor_filled( osell )
osell_stp = push_sell_stop(  quantity: quantity, loss_trig_price: loss_trig_price, loss_price: loss_price)


#------------------------------------------------------------------------------

def push_buy( price, quantity )
	# BUY
	puts "-"*30
	puts "push BUY"
	entry_buy = future_rest.create_order!(
		symbol: 'BTCUSDT',
		side: 'BUY',
		type: 'LIMIT',
		time_in_force: 'GTC',
		quantity: quantity,
		price: price)
	puts entry_buy.inspect
	#entry_buy['clientOrderId']
end

def push_buy_stop( loss_trig_price, loss_price, quantity )
	# STOP loss - put SELL order
	puts "-"*30
	puts "push BUY STOP"
	entry_buy_stoploss = future_rest.create_order!(
		symbol: 'BTCUSDT',
		side: 'SELL',
		type: 'STOP',
		time_in_force: 'GTC',
		quantity: quantity,
		price: loss_price,
		stopPrice: loss_trig_price)
	puts entry_buy_stoploss.inspect
end

#------------------------------------------------------------------------------
def push_sell( price, quantity )
	# SELL
	puts "-"*30
	puts "push SELL"
	entry_sell = future_rest.create_order!(
		symbol: 'BTCUSDT',
		side: 'SELL',
		type: 'LIMIT',
		time_in_force: 'GTC',
		quantity: quantity,
		price: price)
	puts entry_sell.inspect
	#entry_buy['clientOrderId']
end

def push_sell_stop( loss_trig_price, loss_price, quantity )
	# STOP loss - put BUY order
	puts "-"*30
	puts "push SELL STOP"
	push_sell_stop = future_rest.create_order!(
		symbol: 'BTCUSDT',
		side: 'BUY',
		type: 'STOP',
		time_in_force: 'GTC',
		quantity: quantity,
		price: loss_price,
		stopPrice: loss_trig_price)
	puts push_sell_stop.inspect
end

#------------------------------------------------------------------------------

binding.pry
def new_order( obj )
end
# vai chegando orderns
# memorizo evt entrada
# memorizo evt saida
# fecho volatilidade
# OHLC.
# O (Open) – preço de abertura
# H (High)  – máxima
# L (Low) – mínima
# C (Close) – preço de fechamento
def candle
end
# medir velocidade de subida
# ver reversao
# estimar
#
# # fazer codigo para entrar qndo ocorre mudanca
# fazer vela em 1 segundo
# se tendencia igual por mais do que 3 segundos pode entrar
# quando vela mudar entao vender
#
# considerar um thresold minido de 1 pip para entradas e saidas
# observar stop los e gain
