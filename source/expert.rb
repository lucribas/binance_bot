
require 'telegram/bot'


# analises
$position = 0
$position_time = 0

# period in seconds
$candle_period = 20 * 1000
TREND_PERIOD = 5 * 1000
# period in candles
SMA_PERIOD = (3 * 60 * 1000/$candle_period).to_i
BODY_PERIOD = (20 * 1000/$candle_period).to_i
STOP_LOSS = 1.0
BODY_SIZE = 0.3

$renko = []
$candle = []
$volume = []
$oscilator = []
$mma = []
$on_charge = :NONE

$start_bear_price = 0.0
$start_bull_price = 0.0
$sum_profit = 0.0
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

sent_telegram( "connected!" )

def send_trade_info( message )
	$trade.info message
	sent_telegram message
end



def update_candle( trade )
	c = $candle[$position]
	c2 = $candle[$position-1] if $position > 1
	trade_price = trade[:price].to_f
	trade_time  = trade[:time].to_i
	trade_qty =  trade[:qty].to_f
	trade_bull =  trade[:bull]

	#como tratar qndo nao tem trade

	#inside candle
	if trade_time < ($position_time + $candle_period) and $position_time != 0 then
		c[:low]		= trade_price if trade_price < c[:low]
		c[:high] 	= trade_price if trade_price > c[:high]
		c[:close]	= trade_price
		c[:time_close]	= trade_time
		c[:trade_qty]	= c[:trade_qty] + trade_qty
		c[:bodysize]	= (c[:close]-c[:open]).abs;
		c[:sum_bull]	= c[:sum_bull] + ( trade_bull ? trade_qty : 0.0 )
		c[:sum_bear]	= c[:sum_bear] + ( (!trade_bull) ? trade_qty : 0.0 )

		c[:market]	=	(c[:open] == c[:close]) ? :LATERAL : (
							(c[:open] < c[:close]) ? :BULL : :BEAR )

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
		# puts "$position_time = #{$position_time}"
		$candle[$position] = {
			time:  $position_time,
			time_open: trade_time,
			open:  trade_price,
			close: trade_price,
			high:  trade_price,
			low:   trade_price,
			trade_qty: trade_qty,
			sum_bull: ( trade_bull ? trade_qty : 0.0 ),
			sum_bear: ( (!trade_bull) ? trade_qty : 0.0 ),
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
		if c1[:market] == :BEAR then
			c1[:forecast] = :BEAR
		end
	#--- UP SMA
	elsif c1[:trend] == :BULL then
		# detect a trend
		if 	c1[:market] == :BULL then
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

	c = candle[position]
	# forecast, trend, reversion only available in c2
	c2 = candle[position-1] if position > 1
	c3 = candle[position-1] if position > 1

	if $on_charge == :BEAR then
		profit = $start_bear_price - c[:close]
	elsif $on_charge == :BULL then
		profit = c[:close] - $start_bull_price
	else
		profit = 0
	end

	# fast close trade if Change trend
	if $on_charge == :BEAR and
		(
			c[:market] == :BULL and c[:bodysize] > BODY_SIZE or  # current candle changed or
			c2[:market] == :BULL and c2[:bodysize] > BODY_SIZE or  # previous candle
			c2[:trend] == :BULL or	# trend changed
			profit < -STOP_LOSS ) then		# profit reached
		if c[:sum_bull] > 1.0 and
			c[:sum_bull] >= 1.6*c[:sum_bear] then
			$sum_profit = $sum_profit + profit
			$on_charge = :NONE
			# reversion confirmed
			$log.info "N"*30
			$log.info "SHORT_BULL x3 REVERSION CONFIRMED!".yellow
			send_trade_info "CLOSE BEAR: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
			return
		end
	end
	# fast close trade if Change trend
	if $on_charge == :BULL and
		(
			c[:market] == :BEAR and c[:bodysize] > BODY_SIZE or  # current candle changed or
			c2[:market] == :BEAR and c2[:bodysize] > BODY_SIZE or  # previous candle
			c2[:trend] == :BEAR or	# trend changed
			profit < -STOP_LOSS ) then		# profit reached
		if c[:sum_bear] > 1.0 and
			c[:sum_bear] >= 1.6*c[:sum_bull] then
			$sum_profit = $sum_profit + profit
			$on_charge = :NONE

			# reversion confirmed
			$log.info "N"*30
			$log.info "SHORT_BEAR x3 REVERSION CONFIRMED!".yellow
			send_trade_info "CLOSE BULL: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
			return
		end
	end

	# start new trade in NEW TREND
	if !c2.nil? and !c2[:forecast].nil? then
		# $log.info "-"*20
		$log.info "waiting to confirm forecast %s: sum_bull=%.2f sum_bear=%.2f" % [ c2[:forecast].to_s, c[:sum_bull], c[:sum_bear] ]
		# $log.info c2.inspect
		# $log.info c.inspect
		# $log.info $on_charge.to_s
		# # binding.pry
		# $log.info "-"*20

		if c3[:forecast] == :BULL and $on_charge != :BULL and
			c2[:market] == :BULL and
			c[:bodysize] > BODY_SIZE and
			c[:sum_bull] > 1.0 and
			c[:sum_bull] >= 1.6*c[:sum_bear] then
			# forecast confirmed
			if $on_charge == :BEAR then
				$sum_profit = $sum_profit + profit
				send_trade_info "CLOSE BEAR: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
			end
			$log.info "N"*30
			$log.info "BULL FORECAST C3 CONFIRMED!".yellow
			send_trade_info "START BULL: buy %.2f" % c[:close]
			$start_bull_price = c[:close]
			$on_charge = :BULL
			return
		elsif c3[:forecast] == :BEAR and $on_charge != :BEAR and
			c2[:market] == :BEAR and
			c[:bodysize] > BODY_SIZE and
			c[:sum_bear] > 1.0 and
			c[:sum_bear] >= 1.6*c[:sum_bull] then
			# forecast confirmed
			if $on_charge == :BULL then
				$sum_profit = $sum_profit + profit
				send_trade_info "CLOSE BULL: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
			end
			$log.info "N"*30
			$log.info "BEAR FORECAST C3 CONFIRMED!".yellow
			send_trade_info "START BEAR: sell %.2f" % c[:close]
			$start_bear_price = c[:close]
			$on_charge = :BEAR
			return
		end
	end

	# start new trade in NEW TREND
	if !c2.nil? and !c3.nil? and
		$on_charge != :BULL and
		c3[:market] == :BULL and
		c2[:market] == :BULL and
		c2[:trend] == :BULL and
		c[:bodysize] > BODY_SIZE and
		c[:sum_bull] > 1.0 and
		c[:sum_bull] >= 1.6*c[:sum_bear] then
		# forecast confirmed
		if $on_charge == :BEAR then
			$sum_profit = $sum_profit + profit
			send_trade_info "CLOSE BEAR: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
		end
		$log.info "N"*30
		$log.info "BULL TREND c3 c2 CONFIRMED!".yellow
		send_trade_info "START BULL: buy %.2f" % c[:close]
		$start_bull_price = c[:close]
		$on_charge = :BULL
		return
	end

	if !c2.nil? and !c3.nil? and
		$on_charge != :BEAR and
		c3[:market] == :BEAR and
		c2[:trend] == :BEAR and
		c2[:market] == :BEAR and
		c[:bodysize] > BODY_SIZE and
		c[:sum_bear] > 1.0 and
		c[:sum_bear] >= 1.6*c[:sum_bull] then
		# forecast confirmed
		if $on_charge == :BULL then
			$sum_profit = $sum_profit + profit
			send_trade_info "CLOSE BULL: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
		end
		$log.info "N"*30
		$log.info "BEAR TREND c3 c2 CONFIRMED!".yellow
		send_trade_info "START BEAR: sell %.2f" % c[:close]
		$start_bear_price = c[:close]
		$on_charge = :BEAR
		return
	end

	if !c2.nil? and !c2[:reversion].nil? then
		$log.info "waiting to confirm reversion %s: sum_bull=%.2f sum_bear=%.2f" % [ c2[:pattern][:figure].to_s, c[:sum_bull], c[:sum_bear] ]

		if c2[:reversion] == :BULL and $on_charge != :BULL and
			c[:bodysize] > BODY_SIZE and
			c[:sum_bull] > 1.0 and
			c[:sum_bull] >= 1.6*c[:sum_bear] then
			# reversion confirmed
			$log.info "N"*30
			$log.info ("BULL %s REVERSION CONFIRMED!" % c2[:pattern][:figure].to_s ).yellow
			if $on_charge == :BEAR then
				$sum_profit = $sum_profit + profit
				send_trade_info "CLOSE BEAR: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
			end
			send_trade_info "START BULL: buy %.2f" % c[:close]
			$start_bull_price = c[:close]
			$on_charge = :BULL
			return
		elsif c2[:reversion] == :BEAR  and $on_charge != :BEAR and
			c[:bodysize] > BODY_SIZE and
			c[:sum_bear] > 1.0 and
			c[:sum_bear] >= 1.6*c[:sum_bull] then
			# reversion confirmed
			if $on_charge == :BULL then
				$sum_profit = $sum_profit + profit
				send_trade_info "CLOSE BULL: buy %.2f\t\tprofit = %.2f\t\tSUM_profit = %.2f" % [c[:close] , profit, $sum_profit ]
			end
			$log.info "N"*30
			$log.info ("BEAR %s REVERSION CONFIRMED!" % c2[:pattern][:figure].to_s ).yellow
			send_trade_info "START BEAR: sell %.2f" % c[:close]
			$start_bear_price = c[:close]
			$on_charge = :BEAR
			return
		end
	end
# se o volume for maior que 1
# sum_bull = sum trades > open
# sum_bear = sum trades < open
# se > 70% na tendencia entao confirma tendencia

end
