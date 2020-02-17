
#
# Metodos
#

require 'binance'
require 'pry'
require 'json'


class Router

	attr_reader :sum_profit
	attr_reader :on_charge
	attr_reader :on_charge_bull
	attr_reader :on_charge_bear
	attr_reader :on_charge_none
	attr_reader :on_charge_notnone
	attr_reader :on_charge_notbear
	attr_reader :on_charge_notbull
	attr_reader :start_trade_time
	attr_reader :start_bear_price
	attr_reader :start_bull_price
	attr_reader :close_bull_price
	attr_reader :period
	attr_reader :update_time

	SEPARATOR = "-"*40

	def initialize()
		@log_trades_num  = 0
		@sum_profit_pos = 0.0
		@sum_profit_neg = 0.0
		@sum_profit = 0
		@sum_profit_pos_matrix = {}
		@sum_profit_neg_matrix = {}
		@start_bear_price = 0.0
		@start_bull_price = 0.0
		@start_trade_time = 0.0
		@close_trade_time = 0.0
		@period = 0.0
		@update_time = 0.0
		update( state: :NONE )
	end


	def update( state: :NONE )
		@on_charge	= state
		# check the current hand
		@on_charge_bull = (@on_charge == :BULL)
		@on_charge_bear = (@on_charge == :BEAR)
		@on_charge_none = (@on_charge == :NONE)
		@on_charge_notnone = (!@on_charge_none)
		@on_charge_notbear = (!@on_charge_bear)
		@on_charge_notbull = (!@on_charge_bull)
	end


	def update_profit( profit:, start_rule:, close_rule: )
		@log_trades_num = @log_trades_num + 1
		@sum_profit = @sum_profit + profit

		@sum_profit_pos_matrix[ start_rule ] = {} if @sum_profit_pos_matrix[ start_rule ].nil?
		@sum_profit_pos_matrix[ start_rule ][ close_rule ] = 0 if @sum_profit_pos_matrix[ start_rule ][ close_rule ].nil?
		profit_pos = ( (profit>0) ? profit : 0.0 )
		@sum_profit_pos = @sum_profit_pos + profit_pos
		@sum_profit_pos_matrix[ start_rule ][ close_rule ] = @sum_profit_pos_matrix[ start_rule ][ close_rule ] + profit_pos

		@sum_profit_neg_matrix[ start_rule ] = {} if @sum_profit_neg_matrix[ start_rule ].nil?
		@sum_profit_neg_matrix[ start_rule ][ close_rule ] = 0 if @sum_profit_neg_matrix[ start_rule ][ close_rule ].nil?
		profit_neg = ( (profit<0) ? profit : 0.0 )
		@sum_profit_neg = @sum_profit_neg + profit_neg
		@sum_profit_neg_matrix[ start_rule ][ close_rule ] = @sum_profit_neg_matrix[ start_rule ][ close_rule ] + profit_neg
	end

	def get_profit_sts( profit: 0)
		return "profit=%8.2f  [%4d, %8.2f, %8.2f]  liq=%8.2f  efic=%8.4f    \tbar = [%s]" % [profit, @log_trades_num, @sum_profit_pos, @sum_profit_neg, @sum_profit, @sum_profit/@log_trades_num, "X"*profit.abs.to_i] if @log_trades_num>0
	end

	def get_profit_report()
		msg = "sum_profit_pos_matrix: %s\n" % @sum_profit_pos_matrix.inspect
		msg = msg + "sum_profit_neg_matrix: %s\n" % @sum_profit_neg_matrix.inspect
		send_trade_info msg
		puts msg
		puts get_profit_sts()
	end


	def trade_close_bear( close_rule:, time:, start_bear_price:, price:, profit:, msg: )
		if @on_charge == :BEAR then
			@close_trade_time = time
			@update_time = time
			update_profit( profit: profit, start_rule: @start_bear_rule_sv, close_rule: close_rule)
			update( state: :NONE )
			$log_mon.info "N"*30 if $log_mon.log_en?
			$log_mon.info msg.yellow if $log_mon.log_en?
			stime = format_time( time )
			@period = @close_trade_time - @start_trade_time
			t_msg = " CLOSE BEAR: buy  (%4.2f->%4.2f) (%4.0fs)\t\t%s" % [start_bear_price, price, @period/1000, get_profit_sts(profit: profit) ]
			if profit>0 then
				puts (stime + ":" + t_msg).green #if (profit.abs > 30)
			else
				puts (stime + ":" + t_msg).red #if (profit.abs > 30)
			end

			send_trade_info	stime + t_msg
			send_trade_info t_msg
			send_trade_info_send()
		else
			$log_mon.info "ERROR not valid operation".red if $log_mon.log_en?
			binding.pry
		end
	end


	def trade_close_bull( close_rule:, time:, price:, start_bull_price:, profit:, msg: )
		if @on_charge == :BULL then
			@close_trade_time = time
			@update_time = time
			update_profit( profit: profit, start_rule: @start_bull_rule_sv, close_rule: close_rule)
			update( state: :NONE )
			$log_mon.info "N"*30 if $log_mon.log_en?
			$log_mon.info msg.yellow if $log_mon.log_en?
			stime = format_time( time )
			@period = @close_trade_time - @start_trade_time
			t_msg = " CLOSE BULL: sell (%4.2f->%4.2f) (%4.0fs)\t\t%s" % [start_bull_price, price, @period/1000, get_profit_sts(profit: profit) ]

			if profit>0 then
				puts (stime + ":" + t_msg).green #if (profit.abs > 30)
			else
				puts (stime + ":" + t_msg).red #if (profit.abs > 30)
			end

			send_trade_info	stime + t_msg
			send_trade_info t_msg
			send_trade_info_send()
		else
			$log_mon.info "ERROR not valid operation".red if $log_mon.log_en?
			binding.pry
		end
	end

	def trade_start_bull( start_rule: ,time:, price:, msg: )
		# binding.pry
		if @on_charge == :NONE then
			@start_bull_rule_sv = start_rule
			@start_bear_rule_sv = "X"
			@start_trade_time = time
			@update_time = time
			@start_bull_price = price
			update( state: :BULL )
			$log_mon.info msg.yellow if $log_mon.log_en?
			stime = format_time( time )
			# send_trade_info SEPARATOR
			send_trade_info	stime + msg
			send_trade_info	"START BULL: buy  %.2f" % price
			send_trade_info_send()
			# binding.pry
		else
			$log_mon.info "ERROR not valid operation".red if $log_mon.log_en?
			#binding.pry
		end
	end


	def trade_start_bear( start_rule:, time:, price:, msg: )
		if @on_charge == :NONE then
			@start_bear_rule_sv = start_rule
			@start_bull_rule_sv = "X"
			@start_trade_time = time
			@update_time = time
			@start_bear_price = price
			update( state: :BEAR )
			$log_mon.info msg.yellow if $log_mon.log_en?
			stime = format_time( time )
			# send_trade_info SEPARATOR
			send_trade_info	stime + msg
			send_trade_info "START BEAR: sell %.2f" % price
			send_trade_info_send()
			# binding.pry
		else
			$log_mon.info "ERROR not valid operation".red if $log_mon.log_en?
			#binding.pry
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
end
