
# analises
$position = 0
$position_time = 0

# period in seconds
$candle_period = 20 * 1000
REVERSION_PERIOD = 5 * 1000
# period in candles
SMA_PERIOD = (3 * 60 * 1000/$candle_period).to_i
BODY_PERIOD = (20 * 1000/$candle_period).to_i

$renko = []
$candle = []
$volume = []
$oscilator = []
$mma = []

require_relative 'candlestick_patterns'

# indicators
# cross_mma

# def book_update( book )
# end
#
#
# def trade_update( trade )
# end



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

		if trade_time > ($position_time + REVERSION_PERIOD) then
				check_reversion( c, c2)
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
		check_reversion( c, c2)

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
	c1_p = c1[:pattern]
	if !c1_p.nil? then
		c1_pattern = c1_p[:pattern]
		# binding.pry
		#--- DOWN SMA
		if c1[:trend] == :DOWN then
			# detect a reversion
			if PAT_BULL.include?(c1_pattern) then
				c1[:forecast] = :BULL
				c1[:reversion] = :BULL
			end

		#--- UP SMA
		elsif c1[:trend] == :UPPER then
			# detect a reversion
			if PAT_BEAR.include?(c1_pattern) then
				c1[:forecast] = :BEAR
				c1[:reversion] = :BEAR
			end
		end
	end
end


## ADICIONAR MMA e cruzamento
def check_reversion( c, c2 )

	if !c2.nil? and !c2[:reversion].nil? then

		$log.info "waiting for reversion %s: sum_bull=%.2f sum_bear=%.2f" % [ c[:reversion].to_s, c[:sum_bull], c[:sum_bear] ]

		if c2[:reversion] == :BULL and
			c[:sum_bull] > 1.0 and
			c[:sum_bull] >= 1.6*c[:sum_bear] then
			# reversion confirmed
			$log.info "N"*30
			$log.info "BULL REVERSION CONFIRMED!".yellow
		elsif c2[:reversion] == :BEAR and
			c[:sum_bear] > 1.0 and
			c[:sum_bear] >= 1.6*c[:sum_bull] then
			# reversion confirmed
			$log.info "N"*30
			$log.info "BEAR REVERSION CONFIRMED!".yellow
		end

	end
# se o volume for maior que 1
# sum_bull = sum trades > open
# sum_bear = sum trades < open
# se > 70% na tendencia entao confirma tendencia

end
