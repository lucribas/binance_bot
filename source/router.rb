require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'
require 'bigdecimal'
require_relative 'stdoutlog'
require_relative 'secret_keys'


$sum_profit_pos_matrix = {}
$sum_profit_neg_matrix = {}

def update_profit( profit:, start_rule:, close_rule: )
	$trades_num = $trades_num + 1
	$sum_profit = $sum_profit + profit

	$sum_profit_pos_matrix[ start_rule ] = {} if $sum_profit_pos_matrix[ start_rule ].nil?
	$sum_profit_pos_matrix[ start_rule ][ close_rule ] = 0 if $sum_profit_pos_matrix[ start_rule ][ close_rule ].nil?
	profit_pos = ( (profit>0) ? profit : 0.0 )
	$sum_profit_pos = $sum_profit_pos + profit_pos
	$sum_profit_pos_matrix[ start_rule ][ close_rule ] = $sum_profit_pos_matrix[ start_rule ][ close_rule ] + profit_pos

	$sum_profit_neg_matrix[ start_rule ] = {} if $sum_profit_neg_matrix[ start_rule ].nil?
	$sum_profit_neg_matrix[ start_rule ][ close_rule ] = 0 if $sum_profit_neg_matrix[ start_rule ][ close_rule ].nil?
	profit_neg = ( (profit<0) ? profit : 0.0 )
	$sum_profit_neg = $sum_profit_neg + profit_neg
	$sum_profit_neg_matrix[ start_rule ][ close_rule ] = $sum_profit_neg_matrix[ start_rule ][ close_rule ] + profit_neg
end

def get_profit_sts( profit: 0)
	return "profit=%.2f  [%d, %.2f, %.2f]  liq=%.2f  efic=%.4f" % [profit, $trades_num, $sum_profit_pos, $sum_profit_neg, $sum_profit, $sum_profit/$trades_num]
end

def get_profit_report()
	msg = "sum_profit_pos_matrix: %s\n" % $sum_profit_pos_matrix.inspect
	msg = msg + "sum_profit_neg_matrix: %s\n" % $sum_profit_neg_matrix.inspect
	send_trade_info msg
	puts msg
	puts get_profit_sts()
end


def trade_close_bear( close_rule:, time:, price:, profit:, msg: )
	if $on_charge == :BEAR then
		$start_trade_time = time
		update_profit( profit: profit, start_rule: $start_bear_rule_sv, close_rule: close_rule)
		$on_charge = :NONE
		$log.info "N"*30 if $log.log_en?
		$log.info msg.yellow if $log.log_en?
		stime = format_time( time )
		(puts stime + ": CLOSE BEAR: buy  %.2f\t\t%s" % [price, get_profit_sts(profit: profit) ] ) if (profit.abs > 30)
		send_trade_info	stime + msg
		send_trade_info "CLOSE BEAR: buy  %.2f\t\t%s" % [price, get_profit_sts(profit: profit) ]
		send_trade_info_send()
	end
end


def trade_close_bull( close_rule:, time:, price:, profit:, msg: )
	if $on_charge == :BULL then
		$start_trade_time = time
		update_profit( profit: profit, start_rule: $start_bull_rule_sv, close_rule: close_rule)
		$on_charge = :NONE
		$log.info "N"*30 if $log.log_en?
		$log.info msg.yellow if $log.log_en?
		stime = format_time( time )
		(puts stime + ": CLOSE BULL: sell  %.2f\t\t%s" % [price, get_profit_sts(profit: profit) ] ) if (profit.abs > 30)
		send_trade_info	stime + msg
		send_trade_info "CLOSE BULL: sell %.2f\t\t%s" % [price, get_profit_sts(profit: profit) ]
		send_trade_info_send()
	end
end

def trade_start_bull( start_rule: ,time:, price:, msg: )
	if $on_charge == :NONE then
		$start_bull_rule_sv = start_rule
		$start_bear_rule_sv = "X"
		$start_trade_time = time
		$start_bull_price = price
		$on_charge = :BULL
		$log.info msg.yellow if $log.log_en?
		stime = format_time( time )
		send_trade_info SEPAR
		send_trade_info	stime + msg
		send_trade_info	"START BULL: buy  %.2f" % price
		send_trade_info_send()
	end
end


def trade_start_bear( start_rule:, time:, price:, msg: )
	if $on_charge == :NONE then
		$start_bear_rule_sv = start_rule
		$start_bull_rule_sv = "X"
		$start_trade_time = time
		$start_bear_price = price
		$on_charge = :BEAR
		$log.info msg.yellow if $log.log_en?
		stime = format_time( time )
		send_trade_info SEPAR
		send_trade_info	stime + msg
		send_trade_info "START BEAR: sell %.2f" % price
		send_trade_info_send()
	end
end



# testar:
# - colocar buy
# -- usando o stream da conta:
# 	- monitorar o valor
# 	- atualizar qnte filled e valor medio
# 	- mudar estado para BULL/BEAR/NONE

# 	- cancelar pendentes (not filled) e
# 	- se BULL (start) e saldo +, entao completar restante
# 	- se BULL (start) e saldo -, entao completar restante
# 	- se BEAR (close) e saldo +, e buy close qte atual
# 	- se BEAR (close) e saldo -, e buy close qte atual

# 	- atualizar obter o valor de start/profit e qnde em maos

# - colocar sell
# -- usando o stream da conta:
# 	- monitorar o valor
# 	- atualizar qnte filled e valor medio


def monitor_orders()
	open = $future_rest.open_orders symbol: 'BTCUSDT'
	# all orders
	all = $future_rest.all_orders symbol: 'BTCUSDT'
end

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
#res = $future_rest.query_order


def monitor_tradeId( tradeId:, orderId: )
	query = $future_rest.query_order symbol: 'BTCUSDT', origclientOrderId: tradeId #'7itt71O1wo8Y1emxwzxCGw'

	# confirm buy

	query.each { |a|
		#puts a["orderId"]
		if a["orderId"] ==  orderId then  # 250608142
			puts a
		end
	}

end
# -> listener para ticks
# - atualizar monitores
#
# -> listener para update de ordens
# - atualizar monitores
#
# -> dentro do ticker




def to_be_done()
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
end

#------------------------------------------------------------------------------

# windows: $ENV:TRADE_EN=1
# linux: export TRADE_EN=1
$trade_en = ENV.include?("TRADE_EN")


def push_buy( price:, quantity: )
	return if !$trade_en
	# BUY
	send_trade_info "TRADE BUY: #{price}, #{quantity}"
	send_trade_info_send()
	entry_buy = $future_rest.create_order!(
		symbol: 'BTCUSDT',
		side: 'BUY',
		type: 'LIMIT',
		time_in_force: 'GTC',
		quantity: quantity,
		price: price)
	puts entry_buy.inspect
	#entry_buy['clientOrderId']
end

def push_buy_stop( loss_trig_price:, loss_price:, quantity: )
	return if !$trade_en
	# STOP loss - put SELL order
	send_trade_info "TRADE BUY_STOP: #{loss_trig_price}, #{loss_price}, #{quantity} "
	send_trade_info_send()
	entry_buy_stoploss = $future_rest.create_order!(
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
def push_sell( price:, quantity: )
	return if !$trade_en
	# SELL
	send_trade_info "TRADE SELL: #{price}, #{quantity}"
	send_trade_info_send()
	entry_sell = $future_rest.create_order!(
		symbol: 'BTCUSDT',
		side: 'SELL',
		type: 'LIMIT',
		time_in_force: 'GTC',
		quantity: quantity,
		price: price)
	puts entry_sell.inspect
	#entry_buy['clientOrderId']
end

def push_sell_stop( loss_trig_price:, loss_price:, quantity: )
	return if !$trade_en
	# STOP loss - put BUY order
	send_trade_info "TRADE SELL_STOP: #{loss_trig_price}, #{loss_price}, #{quantity}"
	send_trade_info_send()
	push_sell_stop = $future_rest.create_order!(
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
