
require 'telegram/bot'
require_relative 'record_trade'


# fazer funcao para estatistica de trades


# analises
$position = 0
$position_time = 0
$trades_num  = 0
$sum_profit_pos = 0.0
$sum_profit_neg = 0.0

# period in seconds
$candle_period = 20 * 1000
TREND_PERIOD = 0.5 * 1000

CHK_VOL_TH = 0.1
CHK_STOP_HISTERESIS = 2 * 1000
STOP_LOSS = 1.0

CHK_GAIN_HISTERESIS = 20 * 1000
GAIN_MIN = 2.0

SUM_THRESHOLD_FORECAST = 1.6
SUM_THRESHOLD_REVERSION = 0.3

VOL_SIZE = 20.0
VOL_THRESHOLD_FORECAST = 0.5	# 30% of previous
VOL_THRESHOLD_REVERSION = 2.6	# 30% of previous
VOL_AVG_PERIOD = 6

SEPAR = "-"*20

# period in candles
SMA_PERIOD = 6*10
BODY_AVG_PERIOD = 11
exit "error body period" if BODY_AVG_PERIOD > SMA_PERIOD

BODY_SIZE = 2.0

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
$telegram_en = ((!ENV.include?("TELEGRAM_DISABLE")) and (!$play_trade) )
puts "telegram_en: #{$telegram_en}"
# binding.pry
$message_buffer = ""

require_relative 'candlestick_patterns'
require_relative 'router'

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
	$message_buffer = $message_buffer + message + "\n"
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
		#c1[:market_chk]	= (c1[:bodysize] > BODY_SIZE) ? c1[:market] : :NONE
		c1[:market_chk]	= (c1[:bodysize] > 0.7*c1[:avg_bodysize]) ? c1[:market] : :NONE

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
			avg_bodysize: BODY_SIZE,
			avg_trade_qty: VOL_SIZE,
			bodysize: 0,
			flags_bear: [false, false],
			flags_bull: [false, false]
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



## ADICIONAR MMA e cruzamento
def check_trend( candle, position )

	if position < SMA_PERIOD then
		$log.info "waiting for SMA_PERIOD: #{position} < #{SMA_PERIOD}"
		return
	end

	# forecast, trend, reversion only available in c2
	return if position <= 10
	c1 = candle[position]
	c2 = candle[position-1]
	c3 = candle[position-2]
	c4 = candle[position-3]

	if $on_charge == :BEAR then
		profit = $start_bear_price - c1[:close]
	elsif $on_charge == :BULL then
		profit = c1[:close] - $start_bull_price
	else
		profit = 0.0
	end

	#--------------------------------------------------------------------------------------------
	hister			= (c1[:time_close] - $start_trade_time)
	stp_gain_min	= ( (hister > CHK_GAIN_HISTERESIS) and (profit < GAIN_MIN) and ($on_charge != :NONE) )
	# stp_loss		= ( (hister > CHK_STOP_HISTERESIS) and (profit < STOP_LOSS) and ($on_charge != :NONE) )
	stp_loss		= ( (hister > CHK_STOP_HISTERESIS) and (profit < STOP_LOSS) and ($on_charge != :NONE) )
	# slow
	c3_mkt_bull		= (c3[:market_chk] == :BULL)
	c3_mkt_bear		= (c3[:market_chk] == :BEAR)
	c3_trend_bull	= (c3[:trend] == :BULL)
	c3_trend_bear	= (c3[:trend] == :BEAR)

	c2_mkt_bull		= (c2[:market_chk] == :BULL)
	c2_mkt_bear		= (c2[:market_chk] == :BEAR)
	c2_fore_bull	= (c2[:forecast] == :BULL)
	c2_fore_bear	= (c2[:forecast] == :BEAR)
	c2_figure_bull	= (c2[:reversion] == :BULL)
	c2_figure_bear	= (c2[:reversion] == :BEAR)
	c2_trend_bull	= (c2[:trend] == :BULL)
	c2_trend_bear	= (c2[:trend] == :BEAR)
	# fast
	c1_mkt_bull		= (c1[:market_chk] == :BULL)
	c1_mkt_bear		= (c1[:market_chk] == :BEAR)

	vol_th_fore_vl	= [ VOL_THRESHOLD_FORECAST*c1[:avg_trade_qty], VOL_THRESHOLD_FORECAST*VOL_SIZE].min
	vol_th_rev_vl	= [ VOL_THRESHOLD_REVERSION*c1[:avg_trade_qty], VOL_THRESHOLD_REVERSION*VOL_SIZE].min

	c1_thr_fore_bull	= ( (c1[:sum_bull] > vol_th_fore_vl) and (c1[:sum_bull] >= SUM_THRESHOLD_FORECAST*c1[:sum_bear]) )
	c1_thr_fore_bear	= ( (c1[:sum_bear] > vol_th_fore_vl) and (c1[:sum_bear] >= SUM_THRESHOLD_FORECAST*c1[:sum_bull]) )
	c1_thr_rev_bull		= ( (c1[:sum_bull] > vol_th_rev_vl) and (c1[:sum_bull] >= SUM_THRESHOLD_REVERSION*c1[:sum_bear]) )
	c1_thr_rev_bear		= ( (c1[:sum_bear] > vol_th_rev_vl) and (c1[:sum_bear] >= SUM_THRESHOLD_REVERSION*c1[:sum_bull]) )

	# $log.info  "hister = #{c1[:time_close]} - #{$start_trade_time}"
	# $log.info  "hister = #{hister}, stp_gain_min=#{stp_gain_min}, stp_loss=#{stp_loss}"
	# $log.info  "c123 = [#{c1[:market_chk]}, #{c2[:market_chk]}, #{c3[:market_chk]}]"

	rule_bull_03 = ( c2_figure_bull and c1_mkt_bull and c1_thr_rev_bull )
	rule_bear_03 = ( c2_figure_bear and c1_mkt_bear and c1_thr_rev_bear )

	# rule_bull_02 = ( c3_mkt_bull and c2_mkt_bull and c1_mkt_bull and c1_thr_fore_bull)
	# rule_bear_02 = ( c3_mkt_bear and c2_mkt_bear and c1_mkt_bear and c1_thr_fore_bear)
	rule_bull_02 = ( c2_mkt_bull and c1_mkt_bull and c1_thr_fore_bull)
	rule_bear_02 = ( c2_mkt_bear and c1_mkt_bear and c1_thr_fore_bear)

	rule_bull_01 = ( c2_fore_bull and c1_thr_fore_bull )
	rule_bear_01 = ( c2_fore_bear and c1_thr_fore_bear )

	# melhorar o deteccao de trend - muitos falsos
	# rule_bull_04 = ( c2_trend_bull and c1_mkt_bull and c1_thr_fore_bull )
	# rule_bear_04 = ( c2_trend_bear and c1_mkt_bear and c1_thr_fore_bear )

	rule_bull_04 = ( c3_trend_bull and c2_trend_bull and c1_mkt_bull and c1_thr_fore_bull )
	rule_bear_04 = ( c3_trend_bear and c2_trend_bear and c1_mkt_bear and c1_thr_fore_bear )

	rule_bull_05 = false#( stp_gain_min and c1_thr_fore_bull )
	rule_bear_05 = false#( stp_gain_min and c1_thr_fore_bear )
	rule_bull_06 = ( stp_loss and c1_thr_fore_bull )
	rule_bear_06 = ( stp_loss and c1_thr_fore_bear )

	# rule_bull_start	= ( rule_bull_01 or rule_bull_02 or rule_bull_03 or rule_bull_04 )
	# rule_bear_start	= ( rule_bear_01 or rule_bear_02 or rule_bear_03 or rule_bear_04 )
	rule_bull_start	= ( rule_bull_01 or rule_bull_02 )
	rule_bull_start_msg	= [ rule_bull_01, rule_bull_02 ].map { |v| v ? 1 : 0 }.join
	rule_bear_start	= ( rule_bear_01 or rule_bear_02 )
	rule_bear_start_msg	= [ rule_bear_01, rule_bear_02 ].map { |v| v ? 1 : 0 }.join

	# nao usa mais o trend para entrar
	# rule_bull_start	= ( ( (!c1[:flags_bull][0]) and rule_bull_01 ) or ( (!c1[:flags_bull][1]) and rule_bull_02 ) )
	# rule_bear_start	= ( ( (!c1[:flags_bear][0]) and rule_bear_01 ) or ( (!c1[:flags_bear][1]) and rule_bear_02 ) )
	# nao usa o trend para fechar
	rule_bear_close		= (rule_bull_03 or rule_bull_05 or rule_bull_06)
	rule_bear_close_msg = [rule_bull_03, rule_bull_05, rule_bull_06].map { |v| v ? 1 : 0 }.join
	rule_bull_close		= (rule_bear_03 or rule_bear_05 or rule_bear_06)
	rule_bull_close_msg = [rule_bear_03, rule_bear_05, rule_bear_06].map { |v| v ? 1 : 0 }.join

	# c1[:flags_bear] = [(rule_bear_01 or c1[:flags_bear][0]), (rule_bear_02 or c1[:flags_bear][1])]
	# c1[:flags_bull] = [(rule_bull_01 or c1[:flags_bull][0]), (rule_bull_02 or c1[:flags_bear][1])]


	# new indicators
	pos_adj = (c1[:time_close] % $candle_period).to_f
	vol_adj = ((pos_adj>0) ? ($candle_period / pos_adj) : 1)
	vol_increased = ( ( 1.5*c3[:trade_qty] < c2[:trade_qty] ) and ( 0.8*c2[:trade_qty] < (vol_adj*c1[:trade_qty]) ) )


	#vol_increased = ( ( c4[:trade_qty] < c3[:trade_qty] ) and ( c3[:trade_qty] < c2[:trade_qty] ) and ( c2[:trade_qty] < (vol_adj*c1[:trade_qty]) ) )
	#vol_increased = ( c3[:trade_qty] < c2[:trade_qty] )
	# vol_increased = ( ( c3[:trade_qty] < c2[:trade_qty] ) )

	if c2_fore_bull and ($on_charge != :BULL) then
		$log.info "waiting to confirm forecast BULL: %.2f (sum_bull) > %.2f (avg_vol),  > %.2f (bear_thresh)" % [ c1[:sum_bull], vol_th_fore_vl, SUM_THRESHOLD_FORECAST*c1[:sum_bear] ]
	end
	if c2_figure_bull and ($on_charge != :BULL) then
		$log.info "waiting to confirm figure BULL: %.2f (sum_bull) > %.2f (avg_vol),  > %.2f (bear_thresh)" % [ c1[:sum_bull], vol_th_rev_vl, SUM_THRESHOLD_REVERSION*c1[:sum_bear] ]
	end

	if c2_fore_bear and ($on_charge != :BEAR) then
		# binding.pry if (c1[:sum_bear] > 203)
		$log.info "waiting to confirm forecast BEAR: %.2f (sum_bear) > %.2f (avg_vol),  > %.2f (bull_thresh)" % [ c1[:sum_bear], vol_th_fore_vl, SUM_THRESHOLD_FORECAST*c1[:sum_bull] ]
	end
	if c2_figure_bear and ($on_charge != :BEAR) then
		$log.info "waiting to confirm figure BEAR: %.2f (sum_bear) > %.2f (avg_vol),  > %.2f (bull_thresh)" % [ c1[:sum_bear], vol_th_rev_vl, SUM_THRESHOLD_REVERSION*c1[:sum_bull] ]
	end

	rule_bear_msg = [rule_bear_01, rule_bear_02, rule_bear_03, rule_bear_04, rule_bear_05, rule_bear_06].map { |v| v ? 1 : 0 }.join
	rule_bull_msg = [rule_bull_01, rule_bull_02, rule_bull_03, rule_bull_04, rule_bull_05, rule_bull_06].map { |v| v ? 1 : 0 }.join
	rule_msg = $on_charge.to_s + " : bull-bear " + rule_bull_msg + "-" + rule_bear_msg# + " flags=" + c1[:flags_bull].join(",") + "-" + c1[:flags_bear].join(",")
	$log.info rule_msg
	# fast close trade if Change trend
	if (
			rule_bull_01 or
			rule_bull_02 or
			rule_bull_03 or
			rule_bull_04 or
			rule_bull_05 or
			rule_bull_06
		) then
			# binding.pry
			msg = "rule_bull_01: FORECAST " if rule_bull_01
			msg = "rule_bull_02: MKT x3 " if rule_bull_02
			msg = "rule_bull_03: FIGURE REVERSION " if rule_bull_03
			msg = "rule_bull_04: TREND " if rule_bull_04
			msg = "rule_bull_05: STOP_GAIN " if rule_bull_05
			msg = "rule_bull_06: STOP_LOSS " if rule_bull_06
			msg = " %s (%s)-%s:" % [msg, rule_bull_msg, rule_bear_msg]
	end


	# close confirmed
	if ($on_charge == :BEAR and rule_bear_close) then
		# binding.pry if (( "%.2f" % profit ) == "-4.54" )
		trade_close_bear( close_rule: rule_bear_close_msg, time: c1[:time_close], price: c1[:close], profit: profit, msg: msg )
		binding.pry if rule_bear_close_msg == "000"
	end
	# start confirmed
	if ($on_charge != :BULL and rule_bull_start and vol_increased) then
		trade_start_bull( start_rule: rule_bull_start_msg, time: c1[:time_close], price: c1[:close], msg: msg )
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
			msg = "rule_bear_01: FORECAST " if rule_bear_01
			msg = "rule_bear_02: MKT x3 " if rule_bear_02
			msg = "rule_bear_03: FIGURE REVERSION " if rule_bear_03
			msg = "rule_bear_04: TREND " if rule_bear_04
			msg = "rule_bear_05: STOP_GAIN " if rule_bear_05
			msg = "rule_bear_06: STOP_LOSS " if rule_bear_06
			msg = " %s %s-(%s):" % [msg, rule_bull_msg, rule_bear_msg]
			# reversion confirmed
	end

	if ($on_charge == :BULL and rule_bull_close) then
		trade_close_bull( close_rule: rule_bull_close_msg, time: c1[:time_close], price: c1[:close], profit: profit, msg: msg )
	end
	if ($on_charge != :BEAR and rule_bear_start and vol_increased) then
		trade_start_bear( start_rule: rule_bear_start_msg, time: c1[:time_close], price: c1[:close], msg: msg )
		return
	end


# se o volume for maior que 1
# sum_bull = sum trades > open
# sum_bear = sum trades < open
# se > 70% na tendencia entao confirma tendencia

end
