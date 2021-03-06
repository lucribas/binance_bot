

class CandleBot01


	def initialize( param:, log_mon: )
		@param = param
		@log_mon = log_mon
		exit "error body period" if @param[:BODY_AVG_PERIOD] > @param[:SMA_PERIOD]

		@cool_down_time_en = false
		@cool_down_time = 0


		@patterns_as_bull = [
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

		@patterns_as_bear = [
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


		@renko = []
		@candle = []
		@volume = []
		@oscilator = []
		@mma = []
		@sum_profit = 0.0

	end

	def add_router( router: )
		@r = router
	end


	# -----------------------------------------------------------------------------------

	def process_closed_candle( candle:, position: )
		make_forecast( candle: candle, position: position )
		check_stop( candle: candle, position: position )
		check_trend( candle: candle, position: position )
	end

	def process_open_candle( candle:, position: )
		check_trend( candle: candle, position: position )
	end


	# -----------------------------------------------------------------------------------


	def make_forecast( candle:, position: )

	# verify if have a new pattern
	# confirm or deny trend

	# ideas
	# - monitor: mma (fast e slow)
	# - check candle speed to capture a rali
	# - checl vol and trend of last candles
	# - create a new signal for indicate a new trade enter point
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
			c1_reversion = c1_p[:figure]
			# binding.pry
			#--- DOWN SMA
			if c1[:trend] == :BEAR then

				# detect a trend
				if @patterns_as_bear.include?(c1_reversion) then
					c1[:forecast] = :BEAR
				end

				# detect a reversion
				if @patterns_as_bull.include?(c1_reversion) then
					c1[:reversion] = :BULL
				end

			#--- UP SMA
			elsif c1[:trend] == :BULL then
				# detect a trend
				if @patterns_as_bull.include?(c1_reversion) then
					c1[:forecast] = :BULL
				end

				# detect a reversion
				if @patterns_as_bear.include?(c1_reversion) then
					c1[:reversion] = :BEAR
				end
			end
		end
	end


	## tbd: add MMA e crossing
	def check_stop( candle:, position: )

		return if position < @param[:SMA_PERIOD]

		# forecast, trend, reversion only available in c2
		return if position <= 10

		return if (@r.on_charge_none)

		c1 = candle[position]

		if @r.on_charge_bear then
			profit = @r.start_bear_price - c1[:close]
		elsif @r.on_charge_bull then
			profit = c1[:close] - @r.start_bull_price
		else
			profit = 0.0
		end

		hister			= (c1[:time_close] - @r.start_trade_time)
		stp_loss		= ( (hister > @param[:CHK_FASTSTOP_HISTERESIS]) && (profit < @param[:FASTSTOP_LOSS]) && (@r.on_charge_notnone) )
		rule_msg = "fstp"
		msg = "fast STOP_LOSS"

		if (@r.on_charge_bear && stp_loss) then
			# binding.pry if (( "%.2f" % profit ) == "-4.54" )
			# binding.pry
			@r.trade_close_bear( close_rule: rule_msg, time: c1[:time_close], price: c1[:close], start_bear_price: @r.start_bear_price, profit: profit, msg: msg )
		end

		if (@r.on_charge_bull && stp_loss) then
			# binding.pry
			@r.trade_close_bull( close_rule: rule_msg, time: c1[:time_close], price: c1[:close], start_bull_price: @r.start_bull_price, profit: profit, msg: msg )
		end
	end


	#+------------------------------------------------------------------+
	#|   Function to make a decision
	#+------------------------------------------------------------------+

	## tbd: add MMA e crossing
	def check_trend( candle:, position: )

		if position < @param[:SMA_PERIOD] then
			@log_mon.info "waiting for SMA_PERIOD: #{position} < #{@param[:SMA_PERIOD]}"
			return
		end

		# forecast, trend, reversion only available in c2
		return if position <= 10
		# point for previous candles
		c1 = candle[position]
		c2 = candle[position-1]
		c3 = candle[position-2]
		c4 = candle[position-3]

		if @r.on_charge_bear then
			profit = @r.start_bear_price - c1[:close]
		elsif @r.on_charge_bull then
			profit = c1[:close] - @r.start_bull_price
		else
			profit = 0.0
		end

		#--------------------------------------------------------------------------------------------
		# c3
		c3_mkt_bull		= (c3[:market_chk] == :BULL)
		c3_mkt_bear		= (c3[:market_chk] == :BEAR)
		c3_trend_bull	= (c3[:trend] == :BULL)
		c3_trend_bear	= (c3[:trend] == :BEAR)
		#--------------------------------------------------------------------------------------------
		# c2
		c2_mkt_bull		= (c2[:market_chk] == :BULL)
		c2_mkt_bear		= (c2[:market_chk] == :BEAR)
		c2_fore_bull	= (c2[:forecast] == :BULL)
		c2_fore_bear	= (c2[:forecast] == :BEAR)
		c2_rev_bull	= (c2[:reversion] == :BULL)
		c2_rev_bear	= (c2[:reversion] == :BEAR)
		c2_trend_bull	= (c2[:trend] == :BULL)
		c2_trend_bear	= (c2[:trend] == :BEAR)
		#--------------------------------------------------------------------------------------------
		# c1
		c1_mkt_bull		= (c1[:market_chk] == :BULL)
		c1_mkt_bear		= (c1[:market_chk] == :BEAR)


		# some indicators
		# Hi and Low of candle
		hilo1 = (c1[:high]-c1[:low]).abs
		hilo2 = (c2[:high]-c2[:low]).abs
		hilo3 = (c3[:high]-c3[:low]).abs
		hilo4 = (c4[:high]-c4[:low]).abs

		# adjust factor (based in current time of candle)
		pos_adj = (c1[:time_close] % @param[:CANDLE_PERIOD]).to_f
		vol_adj = ((pos_adj>0) ? (@param[:CANDLE_PERIOD] / pos_adj) : 1)
		vol_adj = [vol_adj, @param[:CANDLE_PERIOD]/1000 ].min

		# time histeresis point
		hister			= (c1[:time_close] - @r.start_trade_time)

		# Stop Loss
		stp_gain_min	= ( (hister > @param[:CHK_GAIN_HISTERESIS]) && (profit < @param[:GAIN_MIN]) && (@r.on_charge_notnone) )
		stop_adp		= -(hilo3+hilo2)
		# stp_loss		= ( (hister > @param[:CHK_STOP_HISTERESIS]) && (profit < stop_adp) && (@r.on_charge_notnone) )
		# stp_loss		= ( (hister > @param[:CHK_STOP_HISTERESIS]) && (profit < @param[:STOP_LOSS]) && (@r.on_charge_notnone) )
		# stp_loss		= ( (hister > @param[:CHK_STOP_HISTERESIS]) && (profit < @param[:STOP_LOSS]) && (@r.on_charge_notnone) )
		stp_loss		= ( (profit < stop_adp) && (hister > 120*1000) && (@r.on_charge_notnone) )
		stp_loss2		= false #( (hister > @param[:CHK_STOP_HISTERESIS]) && (profit < @param[:STOP_LOSS]/3) && (@r.on_charge_notnone) )

		# value of Volume Thresholds
		vol_th_fore_vl	= [ @param[:VOL_THRESHOLD_FORECAST]*c1[:avg_trade_qty], @param[:VOL_THRESHOLD_FORECAST]*@param[:VOL_SIZE]].min
		vol_th_rev_vl	= [ @param[:VOL_THRESHOLD_REVERSION]*c1[:avg_trade_qty], @param[:VOL_THRESHOLD_REVERSION]*@param[:VOL_SIZE]].min
		vol_th_fore_vl	= [ @param[:VOL_THRESHOLD_FORECAST]*c1[:avg_trade_qty], @param[:VOL_THRESHOLD_FORECAST]*@param[:VOL_SIZE]].min
		vol_th_rev_vl	= [ @param[:VOL_THRESHOLD_REVERSION]*c1[:avg_trade_qty], @param[:VOL_THRESHOLD_REVERSION]*@param[:VOL_SIZE]].min

		# vol_th_fore_vl = c3[:avg_trade_qty]
		# vol_th_rev_vl = c3[:avg_trade_qty]
		#
		# c1_thr_fore_bull	= ( vol_th_flg  && (c1[:sum_bull] >= @param[:SUM_THRESHOLD_FORECAST]*c1[:sum_bear]) )
		# c1_thr_fore_bear	= ( vol_th_flg  && (c1[:sum_bear] >= @param[:SUM_THRESHOLD_FORECAST]*c1[:sum_bull]) )
		# c1_thr_rev_bull		= ( vol_th_flg  && (c1[:sum_bull] >= SUM_THRESHOLD_REVERSION*c1[:sum_bear]) )
		# c1_thr_rev_bear		= ( vol_th_flg  && (c1[:sum_bear] >= SUM_THRESHOLD_REVERSION*c1[:sum_bull]) )
		#


	     # o vol nao consegue pegar os ganhos
		 vol_th_flg = c3[:avg_trade_qty]<c2[:avg_trade_qty]
		 bull_ind = c2[:low]<c1[:low] || c2[:high]<c1[:high]
		 bear_ind = c2[:low]>c1[:low] || c2[:high]>c1[:high]
		 hilo_ind = (hilo3<hilo2)

		 vol_th_flg_fore =  ( (c3[:trade_qty]<c2[:trade_qty]) && (c2[:trade_qty]<vol_adj*c1[:trade_qty]) ) && (hilo2>1.0)
		 vol_th_flg_rev =   ( (c3[:trade_qty]<c2[:trade_qty]) && (c2[:trade_qty]<vol_adj*c1[:trade_qty]) ) && (hilo2>1.0)
		 vol_th_flg_revc =  ( (c3[:trade_qty]<c2[:trade_qty]) && (c2[:trade_qty]<vol_adj*c1[:trade_qty]) ) && (hilo2>1.0)

		c2_fore_bull_n	= c2_fore_bull && (c2[:sum_bull] >= @param[:SUM_THRESHOLD_FORECAST]*c2[:sum_bear])
		c2_fore_bear_n	= c2_fore_bear && (c2[:sum_bear] >= @param[:SUM_THRESHOLD_FORECAST]*c2[:sum_bull])
		c2_rev_bull_n	=  c2_rev_bull && (c2[:sum_bull] >= @param[:SUM_THRESHOLD_REVERSION]*c2[:sum_bear])
		c2_rev_bear_n	=  c2_rev_bear && (c2[:sum_bear] >= @param[:SUM_THRESHOLD_REVERSION]*c2[:sum_bull])

		c1_fore_bull_n	= (c1[:sum_bull] >= @param[:SUM_THRESHOLD_DR]*@param[:SUM_THRESHOLD_FORECAST]*c1[:sum_bear])
		c1_fore_bear_n	= (c1[:sum_bear] >= @param[:SUM_THRESHOLD_DR]*@param[:SUM_THRESHOLD_FORECAST]*c1[:sum_bull])
		c1_rev_bull_n	= (c1[:sum_bull] >= @param[:SUM_THRESHOLD_DR]*@param[:SUM_THRESHOLD_REVERSION]*c1[:sum_bear])
		c1_rev_bear_n	= (c1[:sum_bear] >= @param[:SUM_THRESHOLD_DR]*@param[:SUM_THRESHOLD_REVERSION]*c1[:sum_bull])


		c1_thr_fore_bull	= ((c1_fore_bull_n && c2_fore_bull_n) && vol_th_flg_fore  && bull_ind)
		c1_thr_fore_bear	= ((c1_fore_bear_n && c2_fore_bear_n) && vol_th_flg_fore  && bear_ind)

		c1_thr_rev_bull		= ((c1_rev_bull_n  && c2_rev_bull_n)  && vol_th_flg_rev   && bull_ind)
		c1_thr_rev_bullc	= ((c1_rev_bull_n  && c2_rev_bull_n)  && vol_th_flg_revc  && bull_ind)
		c1_thr_rev_bear		= ((c1_rev_bear_n  && c2_rev_bear_n)  && vol_th_flg_rev   && bear_ind)
		c1_thr_rev_bearc	= ((c1_rev_bear_n  && c2_rev_bear_n)  && vol_th_flg_revc  && bear_ind)


		# 01 => FORECAST
		# only use the forecast of c2 candle confirmed in c1 threshold
		rule_bull_01 = ( c2_fore_bull && c1_thr_fore_bull )
		rule_bear_01 = ( c2_fore_bear && c1_thr_fore_bear )

		# 02 => MKT x3
		rule_bull_02 = ( c3_mkt_bull && c2_mkt_bull && c1_mkt_bull && c1_thr_fore_bull)
		rule_bear_02 = ( c3_mkt_bear && c2_mkt_bear && c1_mkt_bear && c1_thr_fore_bear)


		# 03 => FIGURE REVERSION
		rule_bull_03  = ( c2_rev_bull && c1_mkt_bull && c1_thr_rev_bull )
		rule_bull_03c = ( c2_rev_bull && c1_mkt_bull && c1_thr_rev_bullc )
		rule_bear_03  = ( c2_rev_bear && c1_mkt_bear && c1_thr_rev_bear )
		rule_bear_03c = ( c2_rev_bear && c1_mkt_bear && c1_thr_rev_bearc )

		# 04 => TREND
		# melhorar o deteccao de trend - muitos falsos
		# rule_bull_04 = ( c2_trend_bull && c1_mkt_bull && c1_thr_fore_bull )
		# rule_bear_04 = ( c2_trend_bear && c1_mkt_bear && c1_thr_fore_bear )

		rule_bull_04 = ( c3_trend_bull && c2_trend_bull && c1_mkt_bull && c1_thr_fore_bull )
		rule_bear_04 = ( c3_trend_bear && c2_trend_bear && c1_mkt_bear && c1_thr_fore_bear )


		# 05 => STOP_GAIN
		rule_bull_05  = ( stp_gain_min && c1_thr_fore_bull )
		rule_bull_05c = ( stp_gain_min && c1_thr_fore_bull )
		rule_bear_05  = (stp_gain_min && c1_thr_fore_bear )
		rule_bear_05c = (stp_gain_min && c1_thr_fore_bear )

		# 06 => STOP_LOSS
		rule_bull_06  = (stp_loss || ( stp_loss2 && c2_mkt_bull) || c1_thr_fore_bull )
		rule_bull_06c = (stp_loss || ( stp_loss2 && c2_mkt_bull) || c1_thr_fore_bull )
		rule_bear_06  = (stp_loss || ( stp_loss2 && c2_mkt_bear) || c1_thr_fore_bear )
		rule_bear_06c = (stp_loss || ( stp_loss2 && c2_mkt_bear) || c1_thr_fore_bear )


		# VOL Increaded detection
		vol_increased = ( ( c3[:trade_qty] < c2[:trade_qty] ) && ( c2[:trade_qty] < (1.2*vol_adj*c1[:trade_qty]) ) && (1.5*hilo3 < hilo2) && (2.0 < hilo2) && (3.0 < hilo2) && (1.0 < hilo1))
		#vol_increased = ( ( c4[:trade_qty] < c3[:trade_qty] ) && ( c3[:trade_qty] < c2[:trade_qty] ) && ( c2[:trade_qty] < (vol_adj*c1[:trade_qty]) ) )
		#vol_increased = ( c3[:trade_qty] < c2[:trade_qty] )
		#vol_increased = ( ( c3[:trade_qty] < c2[:trade_qty] ) )


		# FINAL RULES to trade
		rule_bull_start		= ( rule_bull_01 || rule_bull_02 || rule_bull_03 || rule_bull_04 ) && vol_increased
		rule_bear_start		= ( rule_bear_01 || rule_bear_02 || rule_bear_03 || rule_bear_04 ) && vol_increased
		rule_bear_close		= ( rule_bull_03c || rule_bull_05c || rule_bull_06c )
		rule_bull_close		= ( rule_bear_03c || rule_bear_05c || rule_bear_06c )

		# Cooldown stop - FORCE a pause to start a new trade
		cooldown_stp = ((@cool_down_time_en == true) && (c1[:time_close] < (@cool_down_time + @param[:COOL_DOWN_TMP])))
		# @cooldown_stp_l = @cooldown_stp_c
		# @cooldown_stp_c = cooldown_stp
		# binding.pry if (@cooldown_stp_l==true) && (@cooldown_stp_c==false)






		#-----------------
		# Trend messages
		if @log_mon.log_en? then
			if (c2_fore_bull && @r.on_charge_notbull) then
				@log_mon.info "waiting to confirm forecast to BULL: %.2f (sum_bull) > %.2f (avg_vol),  > %.2f (bear_thresh)" % [ c1[:sum_bull], vol_th_fore_vl, @param[:SUM_THRESHOLD_FORECAST]*c1[:sum_bear] ]
			end
			if (c2_rev_bull && @r.on_charge_notbull) then
				@log_mon.info "waiting to confirm reversion to BULL: %.2f (sum_bull) > %.2f (avg_vol),  > %.2f (bear_thresh)" % [ c1[:sum_bull], vol_th_rev_vl, @param[:SUM_THRESHOLD_REVERSION]*c1[:sum_bear] ]
			end

			if c2_fore_bear && (@r.on_charge_notbear) then
				# binding.pry if (c1[:sum_bear] > 203)
				@log_mon.info "waiting to confirm forecast to BEAR: %.2f (sum_bear) > %.2f (avg_vol),  > %.2f (bull_thresh)" % [ c1[:sum_bear], vol_th_fore_vl, @param[:SUM_THRESHOLD_FORECAST]*c1[:sum_bull] ]
			end
			if c2_rev_bear && (@r.on_charge_notbear) then
				@log_mon.info "waiting to confirm reversion to BEAR: %.2f (sum_bear) > %.2f (avg_vol),  > %.2f (bull_thresh)" % [ c1[:sum_bear], vol_th_rev_vl, @param[:SUM_THRESHOLD_REVERSION]*c1[:sum_bull] ]
			end
		end


		# binding.pry if (c1[:time_close] >= 1575434070924) && ( c1[:sum_bear]>32.0 )

		# ----------------
		# BULL DETECTED

		trade_start_bull_ind = ( (@r.on_charge_notbull && rule_bull_start) && (!cooldown_stp) )
		trade_close_bear_ind = (     @r.on_charge_bear && rule_bear_close)

		# fast close trade if Change trend
		if (trade_close_bear_ind || trade_start_bull_ind) then
				rule_bear_msg = [rule_bear_01, rule_bear_02, rule_bear_03, rule_bear_04, rule_bear_05, rule_bear_06].map { |v| v ? 1 : 0 }.join
				rule_bull_msg = [rule_bull_01, rule_bull_02, rule_bull_03, rule_bull_04, rule_bull_05, rule_bull_06].map { |v| v ? 1 : 0 }.join
				if @log_mon.log_en? then
					rule_msg = @r.on_charge.to_s + " : bull-bear " + rule_bull_msg + "-" + rule_bear_msg# + " flags=" + c1[:flags_bull].join(",") + "-" + c1[:flags_bear].join(",")
					@log_mon.info rule_msg
				end
				# binding.pry
				msg = ""
				msg += "rule_bull_01: FORECAST\n" if rule_bull_01
				msg += "rule_bull_02: MKT x3\n" if rule_bull_02
				msg += "rule_bull_03: FIGURE REVERSION\n" if rule_bull_03
				msg += "rule_bull_04: TREND\n" if rule_bull_04
				msg += "rule_bull_05: STOP_GAIN\n" if rule_bull_05
				msg += "rule_bull_06: STOP_LOSS\n" if rule_bull_06
				msg = " %s (%s)-%s:" % [msg, rule_bull_msg, rule_bear_msg]
		end


		# close confirmed
		if trade_close_bear_ind then
			# binding.pry if (( "%.2f" % profit ) == "-4.54" )
			rule_bear_close_msg = [rule_bull_03, rule_bull_05, rule_bull_06].map { |v| v ? 1 : 0 }.join
			@r.trade_close_bear( close_rule: rule_bear_close_msg, time: c1[:time_close], price: c1[:close], start_bear_price: @r.start_bear_price, profit: profit, msg: msg )
			# binding.pry if rule_bear_close_msg == "000"

			# cool down after close
			trade_start_bull_ind = false
			@cool_down_time_en = true
			@cool_down_time = c1[:time_close]
		end
		# start confirmed
		if trade_start_bull_ind then
			rule_bull_start_msg	= [ rule_bull_01, rule_bull_02 ].map { |v| v ? 1 : 0 }.join
			@r.trade_start_bull( start_rule: rule_bull_start_msg, time: c1[:time_close], price: c1[:close], msg: msg )
			@cool_down_time_en = false
			return
		end



		# ----------------
		# BEAR DETECTED

		trade_start_bear_en = ( ( @r.on_charge_notbear && rule_bear_start) && (!cooldown_stp) )
		trade_close_bull_en = (      @r.on_charge_bull && rule_bull_close)

		# fast close trade if Change trend
		if ( trade_close_bull_en || trade_start_bear_en ) then

				rule_bear_msg = [rule_bear_01, rule_bear_02, rule_bear_03, rule_bear_04, rule_bear_05, rule_bear_06].map { |v| v ? 1 : 0 }.join
				rule_bull_msg = [rule_bull_01, rule_bull_02, rule_bull_03, rule_bull_04, rule_bull_05, rule_bull_06].map { |v| v ? 1 : 0 }.join
				if @log_mon.log_en? then
					rule_msg = @r.on_charge.to_s + " : bull-bear " + rule_bull_msg + "-" + rule_bear_msg# + " flags=" + c1[:flags_bull].join(",") + "-" + c1[:flags_bear].join(",")
					@log_mon.info rule_msg
				end
				msg = ""
				msg += "rule_bear_01: FORECAST\n" if rule_bear_01
				msg += "rule_bear_02: MKT x3\n" if rule_bear_02
				msg += "rule_bear_03: FIGURE REVERSION\n" if rule_bear_03
				msg += "rule_bear_04: TREND\n" if rule_bear_04
				msg += "rule_bear_05: STOP_GAIN\n" if rule_bear_05
				msg += "rule_bear_06: STOP_LOSS\n" if rule_bear_06
				msg = " %s %s-(%s):" % [msg, rule_bull_msg, rule_bear_msg]
				# reversion confirmed
		end

		if trade_close_bull_en then
			rule_bull_close_msg = [rule_bear_03, rule_bear_05, rule_bear_06].map { |v| v ? 1 : 0 }.join
			@r.trade_close_bull( close_rule: rule_bull_close_msg, time: c1[:time_close], price: c1[:close], start_bull_price: @r.start_bull_price, profit: profit, msg: msg )

			# cool down after close
			trade_start_bear_en = false
			@cool_down_time_en = true
			@cool_down_time = c1[:time_close]
		end
		if trade_start_bear_en then
			rule_bear_start_msg	= [ rule_bear_01, rule_bear_02 ].map { |v| v ? 1 : 0 }.join
			@r.trade_start_bear( start_rule: rule_bear_start_msg, time: c1[:time_close], price: c1[:close], msg: msg )
			@cool_down_time_en = false
			# binding.pry
			return
		end


	end
end
