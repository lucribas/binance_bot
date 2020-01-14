

# the ideia to have a pamameter class
# -  allow running multiple bots each with a param class
# -  allow a future optimization parameter class

class CandleBot01_params
	attr_reader :param

	def initialize( set: 0)
		@param = {}
		select( set: set )
	end

	def select( set: )

		@param[:CANDLE_PERIOD] = 30.0 * 1000
		@param[:TREND_PERIOD] = 0 * 1000

		@param[:BODY_SIZE] = 2.0
		@param[:VOL_SIZE] = 10.0


		@param[:CHK_VOL_TH] = 1.1
		@param[:CHK_STOP_HISTERESIS] = 0* 1000
		@param[:STOP_LOSS] = 1.0

		@param[:CHK_GAIN_HISTERESIS] = 2 * 1000
		@param[:GAIN_MIN] = 2.0

		# Thresholds for detection of Trend
		@param[:SUM_THRESHOLD_FORECAST] = 3.6		# Trend forecast confirmed by "sum of bull" x "sum of bear"
		@param[:SUM_THRESHOLD_REVERSION] = 1.2		# Trend forecast confirmed by "sum of bull" x "sum of bear"
		@param[:SUM_THRESHOLD_DR] = 0.7				# Derating

		@param[:VOL_THRESHOLD_FORECAST] = 0.5	# 30% of previous
		@param[:VOL_THRESHOLD_REVERSION] = 1.6	# 30% of previous

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
