require_relative 'Signals/CandlestickPatterns'
require_relative 'Bots/CandleBot01'
require_relative 'Bots/CandleBot01_params'
require_relative 'Router'
require_relative 'Candle'

class TradeExpert

	def initialize( log_mon: )
		@log_mon = log_mon
		# -------
		# Router orders
		@router = Router.new

		# --------
		# Signals
		@signals = {}
		@signals[1] = CandlestickPatterns.new( param: {SMA_PERIOD: 24, BODY_SIZE: 2.0, BODY_AVG_PERIOD: 4.0, VOL_SIZE: 20, VOL_AVG_PERIOD: 4})

		# -------
		# Bots
		@bots	= {}
		@bot_param_1 = CandleBot01_params.new( set: 0 )
		@bots[1] = CandleBot01.new( param: @bot_param_1.param, log_mon: @log_mon )
		@bots.each { |k,b| b.add_router( router: @router ) }

		# NEED FIX ROUTER to allow more than one boot:
		# move profit, trade vols, etc to anoter obj for each bot

		# -------
		# Candles
		@candles = {}
		# candles - 20s 1m 5m 15m
		@candles[:t20s]	= Candle.new( param: { CANDLE_PERIOD: @bot_param_1.param[:CANDLE_PERIOD] }, log_mon: @log_mon)
		# @candles[:t1m]	= Candle.new( period: 60 )
		# @candles[:t5m]	= Candle.new( period: 5*60 )
		# @candles[:t15m]	= Candle.new( period: 15*60 )
		# @candles[:t1h]	= Candle.new( period: 60*60 )

		@candles.each { |k,c|
			 @bots.each { |p,b| c.add_bot_listener( bot: b ) }
			 @signals.each { |p,s| c.add_signal_listener( signal: s ) }
		}

		# renko - 20s 1m 5m 15m

		# -------
		# Indicators

		# MMA
		# cross_mma
		# CoG
		# IRF
		# Osc
		# Preditors
		# Stocastics
		# CandlePatterns

	end

	def get_profit_report()
		@router.get_profit_report()
	end

	def process_book_update( book: )
	end

	def process_orderTradeUpdate( trade )
	end

	def process_ticketTrade( trade: )
		@candles.each { |k,c| c.process_trade( trade ) }
	end
end
