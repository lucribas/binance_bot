


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
		$log.info "N"*30
		$log.info msg.yellow
		send_trade_info	format_time( time ) + msg
		send_trade_info "CLOSE BEAR: buy  %.2f\t\t%s" % [price, get_profit_sts(profit: profit) ]
		send_trade_info_send()
	end
end


def trade_close_bull( close_rule:, time:, price:, profit:, msg: )
	if $on_charge == :BULL then
		$start_trade_time = time
		update_profit( profit: profit, start_rule: $start_bull_rule_sv, close_rule: close_rule)
		$on_charge = :NONE
		$log.info "N"*30
		$log.info msg.yellow
		send_trade_info	format_time( time ) + msg
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
		$log.info msg.yellow
		send_trade_info SEPAR
		send_trade_info	format_time( time ) + msg
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
		$log.info msg.yellow
		send_trade_info SEPAR
		send_trade_info	format_time( time ) + msg
		send_trade_info "START BEAR: sell %.2f" % price
		send_trade_info_send()
	end
end
