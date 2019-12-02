
# analises
$position = 0
$position_time = 0

$candle_period = 10 * 1000
# period in seconds
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
	trade_hand =  trade[:hand].to_f

	#como tratar qndo nao tem trade


	#inside candle
	if trade_time < ($position_time + $candle_period) and $position_time != 0 then
		c[:low]		= trade_price if trade_price < c[:low]
		c[:high] 	= trade_price if trade_price > c[:high]
		c[:close]	= trade_price
		c[:time_close]	= trade_time
		c[:trade_qty]	= c[:trade_qty] + trade_qty
		c[:bodysize]	= (c[:close]-c[:open]).abs;
		c[:handliq]		= c[:handliq] + trade_qty * trade_hand

		# timeout to confirm (30% to 100% of candle time)
		if !c2.nil? and !c2[:reversion].nil? then
			if trade_time > ($position_time + $candle_period*0.3) then
				puts "waiting for reversion.. %s  %.2f" % [ c[:reversion], c[:handliq] ]
				if c[:handliq] > 1.0 and c[:reversion] == :BULL
					# reversion confirmed
					$log.info "N"*30
					$log.info "BULL REVERSION CONFIRMED!".yellow
				end

				if c[:handliq] < -1.0 and c[:reversion] == :BEAR
					# reversion confirmed
					$log.info "N"*30
					$log.info "BEAR REVERSION CONFIRMED!".yellow
				end
			end
		end
	else
		#closed candle
		# process the closed current candlesticks
		if $position > 1 then
			pattern_classifier( $candle, $position )
			make_forecast( $candle, $position )
			$log.info  "candle[#{$position}]:  %s" % $candle[$position].inspect
		end

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
			handliq: trade_qty * trade_hand,
			bodysize: 0}
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

		binding.pry

		#--- DOWN SMA
		if c1[:trend] == :DOWN then
			# detect a reversion
			if PAT_BULL.include?(c1_pattern) then
				c1[:forecast] = :BULL
				c1[:reversion] = :BULL
			end

		#--- UP SMA
		elsif c1[:trend] == :UP then
			# detect a reversion
			if PAT_BEAR.include?(c1_pattern) then
				c1[:forecast] = :BEAR
				c1[:reversion] = :BEAR
			end
		end
	end
end
