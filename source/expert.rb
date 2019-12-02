

require_relative 'candlestick_patterns'


# analises
$position = 0
$position_time = 0

$candle_period = 30000
$renko = []
$candle = []
$volume = []
$oscilator = []
$mma = []

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
	trade_price = trade[:price].to_f
	trade_time  = trade[:time].to_i
	trade_qty =  trade[:qty].to_f

#como tratar qndo nao tem trade
	if trade_time < ($position_time + $candle_period) and $position_time != 0 then
		c[:low]		= trade_price if trade_price < c[:low]
		c[:high] 	= trade_price if trade_price > c[:high]
		c[:close]	= trade_price
		c[:time_close]	= trade_time
		c[:trade_qty]	= c[:trade_qty] + trade_qty
		c[:bodysize]	= (c[:close]-c[:open]).abs;
		#c[:trend] = trade_price == c[:open] ? 0 : (trade_price > c[:open] ? 1 : -1)
	else
		# process the closed current candlesticks
		if $position > 1 then
			pattern_classifier( $candle, $position )
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
			bodysize: 0}
	end
end


# calcular se o candle deve ficar acima ou abaixo
# fazer a media ponderada
# usar no lugar do close


def decision

  # verifica se tem pattern pendente
  # verifica se confirma tendencia

  # observar mma (fast e slow)
  # analise de candle nao tem velocidade para capturar um rali
  # observar o volume e os ultimos candles e tendenncias
  # fazer um indicador de entrada..


# se eu analisar o candle
# se eu confirmar ele com 1pip em ate 10 segundos
# entrar executar operação


end
