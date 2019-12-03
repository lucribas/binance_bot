
require 'telegram/bot'


# fazer funcao para estatistica de trades


# analises
$position = 0
$position_time = 0
$trades_num  = 0
$sum_profit_pos = 0
$sum_profit_neg = 0

# period in seconds
$candle_period = 8 * 1000
TREND_PERIOD = 1 * 1000

CHK_STOP_HISTERESIS = 8 * 1000
STOP_LOSS = 1.5

CHK_GAIN_HISTERESIS = 12 * 1000
GAIN_MIN = 2.0
SUM_THRESHOLD = 1.2

SEPAR = "-"*20+"\n"

# period in candles
SMA_PERIOD = 10
BODY_PERIOD = 8
exit "error body period" if BODY_PERIOD > SMA_PERIOD

BODY_SIZE = 1.5

$renko = []
$candle = []
$volume = []
$oscilator = []
$mma = []
$on_charge = :NONE

$start_bear_price = 0.0
$start_bull_price = 0.0
$start_trade_time = 0.0
$sum_profit = 0.0

# use $env:TELEGRAM_DISABLE=1 to disable
$telegram_en = !ENV.include?("TELEGRAM_DISABLE")
$message_buffer = ""

require_relative 'candlestick_patterns'

# indicators
# cross_mma

# def book_update( book )
# end
#
#
# def trade_update( trade )
# end

def sent_telegram( message )
	Telegram::Bot::Client.run($telegram_token) do |bot|
		bot.api.send_message( chat_id: 43716964, text: message)
	end
end

sent_telegram( "connected!" ) if $telegram_en

def send_trade_info( message )
	$message_buffer = $message_buffer + message
end

def send_trade_info_send
	$trade.info $message_buffer
	sent_telegram $message_buffer if $telegram_en
	$message_buffer = ""
end

def update_candle( trade )
	c1 = $candle[$position]
	trade_price	= trade[:price].to_f
	trade_time  = trade[:time].to_i
	trade_qty	=  trade[:qty].to_f
	trade_bull	=  trade[:bull]

	#como tratar qndo nao tem trade

	#inside candle
	if trade_time < ($position_time + $candle_period) and $position_time != 0 then
		c1[:low]		= trade_price if trade_price < c1[:low]
		c1[:high] 		= trade_price if trade_price > c1[:high]
		c1[:close]		= trade_price
		c1[:time_close]	= trade_time
		c1[:trade_qty]	= c1[:trade_qty] + trade_qty
		c1[:bodysize]	= (c1[:close]-c1[:open]).abs;
		c1[:sum_bull]	= c1[:sum_bull] + ( trade_bull ? trade_qty : 0.0 )
		c1[:sum_bear]	= c1[:sum_bear] + ( (!trade_bull) ? trade_qty : 0.0 )

		c1[:market]		=	(c1[:open] == c1[:close]) ? :LATERAL : (
							(c1[:open] < c1[:close]) ? :BULL : :BEAR )
		c1[:market_chk]	= (c1[:bodysize] > BODY_SIZE) ? c1[:market] : :NONE

		if trade_time > ($position_time + TREND_PERIOD) then
			check_trend($candle, $position)
		end
	else
		#closed candle
		# process the closed current candlesticks
		if $position > 1 then
			pattern_classifier( $candle, $position )
			make_forecast( $candle, $position )
			$log.info  "candle[#{$position}]:  %s" % $candle[$position].inspect
		end

		# previous reversion
		check_trend($candle, $position)

		# initialize the next candlestick
		$position = $position + 1
		$position_time = trade_time - (trade_time % $candle_period)
		# $log.info  "$position_time = #{$position_time}"
		$candle[$position] = {
			time:  $position_time,
			time_open: trade_time,
			time_close: trade_time,
			open:  trade_price,
			close: trade_price,
			high:  trade_price,
			low:   trade_price,
			trade_qty: trade_qty,
			sum_bull: ( trade_bull ? trade_qty : 0.0 ),
			sum_bear: ( (!trade_bull) ? trade_qty : 0.0 ),
			market:   :NONE,
			market_chk: :NONE,
			bodysize: 0
		}
	end
end


# calcular se o candle deve ficar acima ou abaixo
# fazer a media ponderada
# usar no lugar do close

#+------------------------------------------------------------------+
#|   Function to make a decision
#+------------------------------------------------------------------+


PAT_BULL = [
			# pattern, confirm period need, confirm volume need, confirm body need
			:INV_HAMMER_BULL,
			:BELT_HOLD_BULL,
			:ENGULFING_BULL,
			:HARAMI_CROSS_BULL,
			:HARAMI_BULL,
			:DOJI_STAR_BULL,
			:PIERCING_LINE_BULL,
			:MEETING_LINES_BULL,
			:MATCHING_LOW_BULL,
			:HOMING_PIGEON_BULL,
			:KICKING_BULL
		].freeze

PAT_BEAR = [
			:HAMMER_BEAR,
			:INV_HAMMER_BEAR,
			:SHOOTING_STAR_BEAR,
			:BELT_HOLD_BEAR,
			:ENGULFING_BEAR,
			:HARAMI_CROSS_BEAR,
			:HARAMI_BEAR,
			:DOJI_STAR_BEAR,
			:DARK_CLOUD_COVER_BEAR,
			:MEETING_LINES_BEAR,
			:KICKING_BEAR,
			:ON_NECK_LINE_BEAR,
			:IN_NECK_LINE_BEAR,
			:THRUSTING_LINE_BEAR
		].freeze


def make_forecast( candle, position )

  # verifica se tem pattern pendente
  # verifica se confirma tendencia

  # observar mma (fast e slow)
  # analise de candle nao tem velocidade para capturar um rali
  # observar o volume e os ultimos candles e tendenncias
  # fazer um indicador de entrada..


# se eu analisar o candle
# se eu confirmar ele com 1pip em ate 10 segundos
# entrar executar operação


	c1	= candle[position]


	#--- DOWN SMA
	if c1[:trend] == :BEAR then
		# detect a trend
		if c1[:market_chk] == :BEAR then
			c1[:forecast] = :BEAR
		end
	#--- UP SMA
	elsif c1[:trend] == :BULL then
		# detect a trend
		if 	c1[:market_chk] == :BULL then
			c1[:forecast] = :BULL
		end
	end

	c1_p = c1[:pattern]
	if !c1_p.nil? then
		c1_figure = c1_p[:figure]
		# binding.pry
		#--- DOWN SMA
		if c1[:trend] == :BEAR then

			# detect a trend
			if PAT_BEAR.include?(c1_figure) then
				c1[:forecast] = :BEAR
			end

			# detect a reversion
			if PAT_BULL.include?(c1_figure) then
				c1[:reversion] = :BULL
			end

		#--- UP SMA
		elsif c1[:trend] == :BULL then
			# detect a trend
			if PAT_BULL.include?(c1_figure) then
				c1[:forecast] = :BULL
			end

			# detect a reversion
			if PAT_BEAR.include?(c1_figure) then
				c1[:reversion] = :BEAR
			end
		end
	end
end


def update_profit( profif )
	$trades_num = $trades_num + 1
	$sum_profit_pos = $sum_profit_pos + (profit>0) ? profit : 0
	$sum_profit_neg = $sum_profit_pos + (profit<0) ? profit : 0
	$sum_profit = $sum_profit + profit
end

def get_profit_sts()
	return "%d,%.2f,%.2f,%.2f" % [$trades_num, $sum_profit_pos, $sum_profit_neg,$sum_profit]
end

def trade_close_bear( time, price, profit, msg )
	if $on_charge == :BEAR then
		$start_trade_time = time
		update_profit( profit )
		$on_charge = :NONE
		$log.info "N"*30
		$log.info msg.yellow
		send_trade_info	msg
		send_trade_info "CLOSE BEAR: buy %.2f\t\t%s" % [price, get_profit_sts() ]
		send_trade_info_send()
	end
end


def trade_close_bull( time, price, profit, msg )
	if $on_charge == :BULL then
		$start_trade_time = time
		update_profit( profit )
		$on_charge = :NONE
		$log.info "N"*30
		$log.info msg.yellow
		send_trade_info	msg
		send_trade_info "CLOSE BULL: buy %.2f\t\t%s" % [price, get_profit_sts() ]
		send_trade_info_send()
	end
end

def trade_start_bull( time, price, msg )
	if $on_charge == :NONE then
		$start_trade_time = time
		$start_bull_price = prince
		$on_charge = :BULL
		$log.info msg.yellow
		send_trade_info	msg
		send_trade_info SEPAR + "START BULL: sell %.2f" % price
		send_trade_info_send()
	end
end


def trade_start_bear( time, price, msg )
	if $on_charge == :NONE then
		$start_trade_time = time
		$start_bear_price = prince
		$on_charge = :BEAR
		$log.info msg.yellow
		send_trade_info	msg
		send_trade_info SEPAR + "START BEAR: sell %.2f" % price
		send_trade_info_send()
	end
end


## ADICIONAR MMA e cruzamento
def check_trend( candle, position )

	if position < SMA_PERIOD then
		$log.info "waiting for SMA_PERIOD: #{position} < #{SMA_PERIOD}"
		return
	end
	return if position <= 3

	c1 = candle[position]
	return if c1.nil?

	# forecast, trend, reversion only available in c2
	c2 = candle[position-1] if position > 1
	c3 = candle[position-2] if position > 1

	if $on_charge == :BEAR then
		profit = $start_bear_price - c1[:close]
	elsif $on_charge == :BULL then
		profit = c1[:close] - $start_bull_price
	else
		profit = 0
	end

	#--------------------------------------------------------------------------------------------
	hister			= c1[:time_close] - $start_trade_time
	stp_gain_min	= (hister > CHK_GAIN_HISTERESIS) and (profit < GAIN_MIN)
	stp_loss		= (hister > CHK_STOP_HISTERESIS) and (profit < STOP_LOSS)
	c3_mkt_bull		= c3[:market_chk] == :BULL
	c3_mkt_bear		= c3[:market_chk] == :BEAR
	c2_mkt_bull		= c2[:market_chk] == :BULL
	c2_mkt_bear		= c2[:market_chk] == :BEAR
	c2_fore_bull	= c2[:forecast] == :BULL
	c2_fore_bear	= c2[:forecast] == :BEAR
	c2_figure_bull	= c2[:reversion] == :BULL
	c2_figure_bear	= c2[:reversion] == :BEAR
	c2_trend_bull	= c2[:trend] == :BULL and c2_mkt_bull
	c2_trend_bear	= c2[:trend] == :BEAR and c2_mkt_bear
	c1_mkt_bull		= c1[:market_chk] == :BULL
	c1_mkt_bear		= c1[:market_chk] == :BEAR
	c1_thrshld_bull	= c1[:sum_bull] > 1.0 and c1[:sum_bull] >= SUM_THRESHOLD*c1[:sum_bear]
	c1_thrshld_bear	= c1[:sum_bear] > 1.0 and c1[:sum_bear] >= SUM_THRESHOLD*c1[:sum_bull]

	# $log.info  "hister = #{c1[:time_close]} - #{$start_trade_time}"
	# $log.info  "hister = #{hister}, stp_gain_min=#{stp_gain_min}, stp_loss=#{stp_loss}"
	# $log.info  "c123 = [#{c1[:market_chk]}, #{c2[:market_chk]}, #{c3[:market_chk]}]"

	rule_bull_01 = c2_fore_bull and c1_thrshld_bull
	rule_bear_01 = c2_fore_bear and c1_thrshld_bear
	rule_bull_02 = c3_mkt_bull and c2_mkt_bull and c1_thrshld_bull
	rule_bear_02 = c3_mkt_bear and c2_mkt_bear and c1_thrshld_bear
	rule_bull_03 = c2_figure_bull and c1_thrshld_bull
	rule_bear_03 = c2_figure_bear and c1_thrshld_bear
	rule_bull_04 = c2_trend_bull and c1_thrshld_bull
	rule_bear_04 = c2_trend_bear and c1_thrshld_bear
	rule_bull_05 = stp_gain_min and c1_thrshld_bull
	rule_bear_05 = stp_gain_min and c1_thrshld_bear
	rule_bull_06 = stp_loss and c1_thrshld_bull
	rule_bear_06 = stp_loss and c1_thrshld_bear

	if c2_fore_bull or c2_fore_bear then
		$log.info "waiting to confirm forecast %s: sum_bull=%.2f sum_bear=%.2f" % [ c2[:forecast].to_s, c1[:sum_bull], c1[:sum_bear] ]
	end
	if c2_figure_bull or c2_figure_bear then
		$log.info "waiting to confirm figure %s: sum_bull=%.2f sum_bear=%.2f" % [ c2[:reversion].to_s, c1[:sum_bull], c1[:sum_bear] ]
	end

	# fast close trade if Change trend
	if (
			rule_bull_01 or
			rule_bull_02 or
			rule_bull_03 or
			rule_bull_04 or
			rule_bull_05 or
			rule_bull_06
		) then
			msg = "rule_bull_01: FORECAST_BULL" if rule_bull_01
			msg = "rule_bull_02: MKT x3" if rule_bull_02
			msg = "rule_bull_03: FIGURE REVERSION" if rule_bull_03
			msg = "rule_bull_04: TREND" if rule_bull_04
			msg = "rule_bull_05: STOP_GAIN" if rule_bull_05
			msg = "rule_bull_06: STOP_LOSS" if rule_bull_06
			trade_close_bear( time: c1[:time_close], price: c1[:close], profit: profit, msg: msg )
			# reversion confirmed
			trade_start_bull( time: c1[:time_close], price: c1[:close], msg: msg )
			return
	end

	# fast close trade if Change trend
	if (
			rule_bear_01 or
			rule_bear_02 or
			rule_bear_03 or
			rule_bear_04 or
			rule_bear_05 or
			rule_bear_06
		) then
			msg = "rule_bear_01: FORECAST_BULL" if rule_bear_01
			msg = "rule_bear_02: MKT x3" if rule_bear_02
			msg = "rule_bear_03: FIGURE REVERSION" if rule_bear_03
			msg = "rule_bear_04: TREND" if rule_bear_04
			msg = "rule_bear_05: STOP_GAIN" if rule_bear_05
			msg = "rule_bear_06: STOP_LOSS" if rule_bear_06
			trade_close_bull( time: c1[:time_close], price: c1[:close], profit: profit, mgs: msg )
			# reversion confirmed
			trade_start_bear( time: c1[:time_close], price: c1[:close], mgs: msg )
			return
	end



# se o volume for maior que 1
# sum_bull = sum trades > open
# sum_bear = sum trades < open
# se > 70% na tendencia entao confirma tendencia

end
