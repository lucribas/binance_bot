require_relative 'Strategies/StrategyBot_1'
require_relative 'Router'

class TradeExpert

	def initialize(  )

		# -------
		# Router orders
		@router = Router.new

		# -------
		# Bots
		@bots	= {}

		@bot_param_1 = StrategyBot_1_params.new( set: 0 )
		@bots[1] = StrategyBot_1.new( param: @bot_param_1.param )

		@bots.each { |k,b| b.add_router( @router ) }

		# -------
		# Graphs
		@candles = {}
		# candles - 20s 1m 5m 15m
		@candles[:t20s]	= Candle.new( period: 20 )
		# @candles[:t1m]	= Candle.new( period: 60 )
		# @candles[:t5m]	= Candle.new( period: 5*60 )
		# @candles[:t15m]	= Candle.new( period: 15*60 )
		# @candles[:t1h]	= Candle.new( period: 60*60 )

		@candles.each { |k,c| c.add_listener( bots: @bots ) }

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


	def process_book_update( book: )
	end

	def process_orderTradeUpdate( trade )
	end

	def process_ticketTrade( trade: )
		@candle.process_trade( trade )
	end
end
