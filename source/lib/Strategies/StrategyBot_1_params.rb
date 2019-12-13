

# a ideia é depois fazer uma classe capaz de gerar instancias de parametros usando ranges
# depois fazer otimização

class StrategyBot_1_params
	attr_reader :param

	def initialize( set: 0)
		@param = {}
		select( set )
	end

	def select( set: )

		@param[:CANDLE_PERIOD] = 160.0 * 1000
		@param[:TREND_PERIOD] = 0 * 1000

		@param[:BODY_SIZE] = 2.0
		@param[:VOL_SIZE] = 20.0


		@param[:CHK_VOL_TH] = 0.1
		@param[:CHK_STOP_HISTERESIS] = 0* 1000
		@param[:STOP_LOSS] = -3.0

		@param[:CHK_GAIN_HISTERESIS] = 20 * 1000
		@param[:GAIN_MIN] = 2.0

		@param[:SUM_THRESHOLD_FORECAST] = 2.6
		@param[:SUM_THRESHOLD_REVERSION] = 1.6
		@param[:SUM_THRESHOLD_DR] = 0.7


		@param[:VOL_THRESHOLD_FORECAST] = 0.5	# 30% of previous
		@param[:VOL_THRESHOLD_REVERSION] = 2.6	# 30% of previous

		@param[:SEPAR] = "-"*20

		@param[:MA_7] 	= 7 * @param[:CANDLE_PERIOD]
		@param[:MA_25] 	= 25 * @param[:CANDLE_PERIOD]
		@param[:MA_99] 	= 99 * @param[:CANDLE_PERIOD]

		# period in candles
		@param[:SMA_PERIOD] = 6*4
		@param[:BODY_AVG_PERIOD] = 4
		@param[:VOL_AVG_PERIOD] = 4

		@param[:COOL_DOWN_TMP] = 5*1000

	end
end
