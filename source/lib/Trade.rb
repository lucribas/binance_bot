
require_relative 'Utils'
require_relative 'TradePersistence'
require_relative 'TradeExpert'

require 'bigdecimal'


# global variable
$diff = 0


class Trade
	attr_reader :trade_rec_disable
	attr_accessor :trade_realtime_disable
	attr_accessor :trade_test_mode

	def initialize( rec_trade: nil, log_mon: nil, future_rest:)
		@rec_trade = rec_trade
		@log_mon = log_mon
		@future_rest = future_rest

		# TRADE_REC_DISABLE
		@trade_disable		= ENV.include?("TRADE_DISABLE")
		@log_mon.info "Disabled trade" if @trade_disable

		# TRADE_REC_DISABLE
		@trade_rec_disable		= ENV.include?("TRADE_REC_DISABLE")
		@log_mon.info "Disabled trade recording" if @trade_rec_disable
		# TRADE_REALTIME_DISABLE
		@trade_realtime_disable	= ENV.include?("TRADE_REALTIME_DISABLE")
		@log_mon.info "Disabled sending the current clock to Binance, the time is adjusted to meet Binance server limits" if @trade_rec_disable
		# TRADE_TEST_MODE
		@trade_test_mode		= ENV.include?("TRADE_TEST_MODE")
		@log_mon.info "Disabled real trading. Trades are emulated. Also disable the Account/Order monitors" if @trade_test_mode

		@trade_expert = TradeExpert.new( log_mon: log_mon )
	end

	def on_open()
		@log_mon.info 'connected'
		sent_telegram( "connected to binance!" ) if $telegram_en
	end

	def on_close()
		@log_mon.info 'closed'
		sent_telegram( "CLOSE binance!" ) if $telegram_en
	end

	def on_error(e)
		@log_mon.info e.inspect
	end

	def check_latency()
		# binding.pry
		$u = Utils.new
		$latency = $u.binance_latency(num: 1, log_mon: @log_mon, future_rest: @future_rest)

		# workaround to windows PC with bad clock
		if @trade_realtime_disable then
			$diff = $latency
			@log_mon.info "# workaround for windows PC with bad clock (latency=#{$latency}) => diff=#{$diff}, NOT_REALTIME_TRADING_FIX MODE"
			# tbd
			# use Refinements in DateTime.now instead change binance lib code ()? check
			#https://ruby-doc.org/core-2.3.0/doc/syntax/refinements_rdoc.html
		elsif $latency>0 || $latency<-15 then
			msg = "# PC with bad clock (latency=#{$latency} > 0), EXITING\n"
			msg += "(1) please run NTP client synchronizer in your PC\n"
			msg += "(2) use a workaround for Testing - sending a timestamp adjusted to Binance - not recomended to REAL TRADING!\n"
			msg += " # windows: $ENV:TRADE_REALTIME_DISABLE=1\n"
			msg += " # linux: export TRADE_REALTIME_DISABLE=1\n"
			@log_mon.info msg
			sent_telegram( msg ) if $telegram_en
			exit(-1)
		else
			@log_mon.info "# considering diff=#{$diff}, measured latency=#{$latency}"
		end
	end

	def new_btcusdt_aggTrade( obj )
		s_local = $s_local.to_f - $diff
		obj_data	= obj["data"]
		event_time	= obj_data["E"]
		trade_time	= obj_data["T"]
		price		= obj_data["p"].to_f
		qty			= obj_data["q"].to_f
		bull		= obj_data["m"] ? false: true

		trade_obj = { :price => price, :time => trade_time.to_i, :event => event_time.to_i, :qty => qty, :bull => bull }


		@rec_trade.record( trade_obj ) if !@trade_rec_disable
		@trade_expert.process_ticketTrade( trade: trade_obj ) if !@trade_disable

		if true then
			message		= " %s -> %s [%3.2fms] : %.2f (%s) - %.6f" %
			[
				format_time( event_time ),
				format_time( trade_time ),
				(s_local*1000-event_time),
				price, #vl
				obj_data["m"]?"bid":"ask",
				qty #qty
			]
			#if f_val>=0.002 then
			message = message + " " + "X"*qty.to_i
			if bull then
				@log_mon.info message.cyan
			else
				@log_mon.info message.red
			end

		end
	end


	def btcusdt_depth5( obj )
		s_local = $s_local.to_f - $diff
		obj_data	= obj["data"]
		event_time	= obj_data["E"]
		trade_time	= obj_data["T"]

		#book_obj = {}
		#@trade_expert.process_book_update( book_obj )

		#binding.pry
		message		= " %s -> %s [%3.2fms] : %.2f - %.2f" %
		[
			format_time( event_time ),
			format_time( trade_time ),
			(s_local*1000-event_time),
			obj_data["b"].first[0],  # specific for future
			obj_data["a"].first[0]  # specific for future
		]
		@log_mon.info message.yellow
	end

	def orderTradeUpdate( obj )
		event_time = obj["E"]
		trade_time = obj["T"]

		#order_obj = { }
		#@trade_expert.process_orderTradeUpdate( order_obj )

		# puts obj.inspect
		message = "[%s] %s -> %s : %s %s at %s (%s)" %
		[
			obj["e"],
			format_time( event_time ),
			format_time( trade_time ),
			obj["o"]["S"], 		# S  Side
			obj["o"]["z"], 		# Order Filled Accumulated Quantity
			obj["o"]["ap"],		# ap Average Price
			obj["o"]["X"],		# X  Order Status
		]
		@log_mon.info message.yellow
	end

	def accountUpdate( obj )
		s_local = $s_local.to_f + $diff
		event_time = obj["E"]
		trade_time = obj["T"]
		# puts obj.inspect
		obj["a"]["B"].each { |b|
			if b["a"]=="USDT" then
				message = "[%s] %s -> %s [%3.2fms] : %s: %s" %
				[
					obj["e"],
					format_time( event_time ),
					format_time( trade_time ),
					(s_local*1000-event_time),
					b["a"],
					b["wb"]
				]
				@log_mon.info message.yellow
			end
		}
	end



	def read_all( file_name: )
		play_trade = PlayTrade.new( file_name )

		n_trades = 0
		time_start = Time.now
		trade_obj = play_trade.read()
		log_start = trade_obj[:time]
		puts '-'*120
		while !trade_obj.nil? do
			n_trades += 1
			if ((n_trades % 10000)==0 ) then
				print sformat_time( trade_obj[:time] )+ "\r"
			end
			$stdout.flush
			# puts "recoved: " + trade_obj.inspect
			print_trade( trade_obj ) if @log_mon.log_en?
			@trade_expert.process_ticketTrade( trade: trade_obj )
			log_end = trade_obj[:time]
			trade_obj = play_trade.read()
		end
		time_end = Time.now
		puts '-'*120
		puts "log stared in %s and ended in %s -> %.2f hours" % [sformat_time(log_start), sformat_time(log_end), (log_end-log_start)/3600000]
		puts "total processed = #{n_trades} trades"
		puts "total time = %.2f s" % (time_end.to_f-time_start.to_f)
		puts "throughput = %.2f trades/s" % (n_trades/(time_end.to_f-time_start.to_f))
		puts '-'*120
		@trade_expert.get_profit_report()
		puts '-'*120
	end


end





















# quando FILLED
# {"e"=>"ORDER_TRADE_UPDATE",  		// "e" Event Type
#  "T"=>1575052059911,				// "T" Transaction Time
#  "E"=>1575052059920,				// "E" Event Time
#  "o"=>
#   {
	# "s"=>"BTCUSDT",					// "s"  Symbol
	# "c"=>"web_DExU2JS1aXEOAS3iWylx",	// "c"  Client Order Id
	# "S"=>"SELL",						// "S"  Side
	# "o"=>"MARKET",					// "o"  Order Type
	# "f"=>"GTC",						// "f"  Time in Force
	# "q"=>"0.010",						// "q"  Original Quantity
	# "p"=>"0.00",						// "p"  Price
	# "ap"=>"7744.75000",				// "ap  Average Price
	# "sp"=>"0.00",						// "sp  Stop Price
	# "x"=>"TRADE",						// "x"  Execution Type
	# "X"=>"FILLED",					// "X"  Order Status
	# "i"=>250903870,					// "i"  Order Id
	# "l"=>"0.010",						// "l"  Order Last Filled Quantity
	# "z"=>"0.010",						// "z"  Order Filled Accumulated Quantity
	# "L"=>"7744.75",					// "L"  Last Filled Price
	# "n"=>"0.01548949",				// "n"  Commission, will not push if no commission
	# "N"=>"USDT",						// "N"  Commission Asset, will not push if no commission
	# "T"=>1575052059911,				// "T"  Order Trade Time
	# "t"=>15917929,					// "t"  Trade Id
	# "b"=>"75.12000",					// "b"  Bids Notional
	# "a"=>"7.74967",					// "a"  Ask Notional
	# "m"=>false,						// "m"  Is this trade the maker side?
	# "R"=>true,						// "R"  Is this reduce only
	# "wt"=>"CONTRACT_PRICE",			// "wt  stop price working type
	# "ot"=>"MARKET"}}
	#
