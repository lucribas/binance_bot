

require_relative 'Strategies/StrategyBot_1'
require_relative 'Router'


class TradeExpert

	def initialize(  )
		# order router
		@router = Router.new

		# Bot
		@bot_param_1 = StrategyBot_1_params.new( set: 0 )
		@bot1 = StrategyBot_1.new( param: @bot_param_1.param )
		@bot1.add_router( @router )

		# representation
		# candles - 20s 1m 5m 15m
		@candle = Candle.new
		@candle.add_listener( @bot1 )
		# renko - 20s 1m 5m 15m

		# indicators
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
