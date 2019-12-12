
require_relative 'Signals/CandlestickPatterns'
require_relative 'Strategies/StrategyBot_1'
require_relative 'Router'

# analises
$position = 0
$position_time = 0
$log_trades_num  = 0
$sum_profit_pos = 0.0
$sum_profit_neg = 0.0

# period in seconds
CANDLE_PERIOD = 20.0
$candle_period = CANDLE_PERIOD * 1000
TREND_PERIOD = 0 * 1000

VOL_SIZE = 20.0
BODY_SIZE = 2.0

$renko = []
$candle = []
$volume = []
$oscilator = []
$mma = []


# indicators
# cross_mma

# representation
# candles - 20s 1m 5m 15m
# renko - 20s 1m 5m 15m

# indicators
# MMA
# CoG
# IRF
# Osc
# Preditors
# Stocastics
# CandlePatterns



# def book_update( book )
# end

# def trade_update( trade )
# end




def update_candle( trade )
	c1 = $candle[$position]
	# binding.pry
	trade_price	= trade[:price].to_f
	trade_time  = trade[:time].to_i
	trade_qty	=  trade[:qty].to_f
	trade_bull	=  trade[:bull]

	#como tratar qndo nao tem trade

	#inside candle
	if trade_time < ($position_time + $candle_period) && $position_time != 0 then
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
		pos_adj = (c1[:time_close] % $candle_period).to_f
		vol_adj = 1 #((pos_adj>0) ? ($candle_period / pos_adj) : 1)
		c1[:market_chk]	= (c1[:bodysize] > 0.7*vol_adj*c1[:avg_bodysize]) ? c1[:market] : :NONE

		#check_stop($candle, $position)

		if trade_time > ($position_time + TREND_PERIOD) then
			check_trend($candle, $position)
		end
	else
		#closed candle
		# process the closed current candlesticks
		if $position > 1 then
			pattern_classifier( $candle, $position )
			make_forecast( $candle, $position )
			$log_mon.info  "candle[#{$position}]:  %s" % $candle[$position].inspect if $log_mon.log_en?
		end

		# previous reversion
		check_trend($candle, $position)

		# initialize the next candlestick
		$position = $position + 1
		$position_time = trade_time - (trade_time % $candle_period)
		# $log_mon.info  "$position_time = #{$position_time}" if $log_mon.log_en?
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
