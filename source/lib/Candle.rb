

class Candle

	def initialize( param:, log_mon: )
		@param = param
		@log_mon = log_mon
		# analises
		@position = 0
		@position_time = 0
		@bots = []
		@signals = []
		@candle = []
	end


	def add_bot_listener( bot: )
		@bots.push( bot )
	end

	def add_signal_listener( signal: )
		@signals.push( signal )
	end

	def process_trade( trade )

		c1 = @candle[@position]
		# binding.pry
		trade_price	= trade[:price].to_f
		trade_time  = trade[:time].to_i
		trade_qty	=  trade[:qty].to_f
		trade_bull	=  trade[:bull]

		#como tratar qndo nao tem trade

		#inside candle
		if trade_time < (@position_time + @param[:CANDLE_PERIOD]) && @position_time != 0 then
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
			#c1[:market_chk]	= (c1[:bodysize] > @param[:BODY_SIZE]) ? c1[:market] : :NONE
			pos_adj = (c1[:time_close] % @param[:CANDLE_PERIOD]).to_f
			vol_adj = 1 #((pos_adj>0) ? (@param[:CANDLE_PERIOD] / pos_adj) : 1)


			#check
			#c1[:market_chk]	= (c1[:bodysize] > 0.7*vol_adj*c1[:avg_bodysize]) ? c1[:market] : :NONE

			#check_stop(candle: @candle, position: @position)

			# if trade_time > (@position_time + @param[:TREND_PERIOD]) then
			#	check_trend(candle: @candle, position: @position)
			# end

			@bots.each { |b| b.process_open_candle(candle: @candle, position: @position) }


		else
			#closed candle
			# process the closed current candlesticks
			if @position > 1 then
				@signals.each { |s| s.process_closed_candle(candle: @candle, position: @position) }
				@bots.each { |b| b.process_closed_candle(candle: @candle, position: @position) }

				@log_mon.info  "candle[#{@position}]:  %s" % @candle[@position].inspect if @log_mon.log_en?
			end

			# previous reversion
			# check_trend(candle: @candle, position: @position)

			# initialize the next candlestick
			@position = @position + 1
			@position_time = trade_time - (trade_time % @param[:CANDLE_PERIOD])
			# @log_mon.info  "@position_time = #{@position_time}" if @log_mon.log_en?
			@candle[@position] = {
				time:  @position_time,
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
				avg_bodysize: 0,
				avg_trade_qty: 0,
				bodysize: 0,
				flags_bear: [false, false],
				flags_bull: [false, false]
			}
		end
	end
end
