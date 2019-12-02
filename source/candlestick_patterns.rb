
require_relative 'candlestick_patterns_classifier'


# based on
# https://www.mql5.com/pt/articles/101
#
#+------------------------------------------------------------------+
#|   TYPE_CANDLESTICK
#+------------------------------------------------------------------+
:CAND_NONE           #Unknown
:CAND_MARIBOZU       #Maribozu
:CAND_MARIBOZU_LONG  #Maribozu long
:CAND_DOJI           #Doji
:CAND_SPIN_TOP       #Spins
:CAND_HAMMER         #Hammer
:CAND_INVERT_HAMMER  #Inverted Hammer
:CAND_LONG           #Long
:CAND_SHORT          #Short
:CAND_STAR           #Star


#+------------------------------------------------------------------+
#|   TYPE_TREND                                                     |
#+------------------------------------------------------------------+
# TYPE_TREND
:UPPER    #Ascending
:DOWN     #Descending
:LATERAL  #Lateral

#+------------------------------------------------------------------+
#|   CANDLE_STRUCTURE                                               |
#+------------------------------------------------------------------+
# struct CANDLE_STRUCTURE
#   {
#    double            openhighlowclose; # OHLC
#    datetime          time;     #Time
#    TYPE_TREND        trend;    #Trend
#    bool              bull;     #Bullish candlestick
#    double            bodysize; #Size of body
#    TYPE_CANDLESTICK  type;     #Type of candlestick
#   };
#+------------------------------------------------------------------+
#|   Function of determining of candlestick                         |
#+------------------------------------------------------------------+


def pattern_classifier( candle, position )

	b	= candle[position-1]
	c	= candle[position]

	#binding.pry
	# bullish or bearish candlestick
	c[:market]	=	(c[:open] == c[:close]) ? :LATERAL : (
						(c[:open] < c[:close]) ? :BULL : :BEAR )
	c[:bull]	= (c[:market] == :BULL)

	# SMA trend
	sma_sum_close	= 0
	num	= 0
	for i in [1, position-SMA_PERIOD].max..position do
		sma_sum_close	= sma_sum_close + candle[i][:close]
		num				= num + 1
	end
	sma_avg_close	= sma_sum_close/num
	c[:trend]	= (sma_avg_close == c[:close]) ? :LATERAL : (
					 (sma_avg_close < c[:close]) ? :UPPER : :DOWN )
	# Get sizes of shadows
	if (c[:market] == :BULL) then
		c[:shade_low]	= c[:open]-c[:low];
		c[:shade_high]	= c[:high]-c[:close];
	else
		c[:shade_low]	= c[:close]-c[:low];
		c[:shade_high]	= c[:high]-c[:open];
	end
	hl = (c[:high]-c[:low]).abs;

	# Calculate average size of body of previous candlesticks
	avg_bodysize = 0
	sum_bodysize = 0
	num	= 0
	for i in [1, position-BODY_PERIOD].max..position do
		if candle[i][:type] != :CAND_DOJI and candle[i][:bodysize] > 2 then
			sum_bodysize	= sum_bodysize + candle[i][:bodysize]
			num				= num + 1
		end
	end
	avg_bodysize = sum_bodysize/num if num>0
	c[:avg_bodysize] = avg_bodysize

	#--- Determine type of candlestick
	c[:type]	= :CAND_NONE;
	#--- long
	c[:type]	= :CAND_LONG if (c[:bodysize] > avg_bodysize*1.3) and num>0
	#--- sort
	c[:type]	= :CAND_SHORT if (c[:bodysize] < avg_bodysize*0.5) and num>0
	#--- doji
	c[:type]	= :CAND_DOJI if (c[:bodysize] < hl*0.03) and num>0
	#--- maribozu
	if (  ( c[:shade_low] < c[:bodysize]*0.01 or c[:shade_high] < c[:bodysize]*0.01 ) and
		c[:bodysize] > 0 ) and num>0 then
			if (	c[:type] == :CAND_LONG ) then
					c[:type] = :CAND_MARIBOZU_LONG;
			else
				c[:type] = :CAND_MARIBOZU
			end
	end

	#--- hammer
	c[:type]	= :CAND_HAMMER if ( c[:shade_low] > c[:bodysize]*2 and c[:shade_high] < c[:bodysize]*0.1)
	#--- invert hammer
	c[:type]	= :CAND_INVERT_HAMMER if ( c[:shade_low] < c[:bodysize]*0.1 and c[:shade_high] > c[:bodysize]*2)

	#--- spinning top
	c[:type]	= :CAND_SPIN_TOP if ( c[:type]==:CAND_SHORT and c[:shade_low] > c[:bodysize] and c[:shade_high] > c[:bodysize])

	c[:patten] = pattern( candle, position )
end
#+------------------------------------------------------------------+
