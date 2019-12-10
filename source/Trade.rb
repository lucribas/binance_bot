


class Trade

	def initialize()
	end

	def on_open()
		$log.info 'connected'
		sent_telegram( "connected to binance!" ) if $telegram_en
	end

	def on_close()
		$log.info 'closed'
		sent_telegram( "CLOSE binance!" ) if $telegram_en
	end

	def on_error()
		$log.info e.inspect
	end



	def new_btcusdt_aggTrade()
		s_local = $s_local.to_f + $diff

		obj_data	= obj["data"]
		event_time	= obj_data["E"]
		trade_time	= obj_data["T"]
		bull		= obj_data["m"] ? false: true
		message		= " %s -> %s [%3.2fms] : %.2f (%s) - %.6f" %
		[
			format_time( event_time ),
			format_time( trade_time ),
			(s_local*1000-event_time),
			obj_data["p"], #vl
			obj_data["m"]?"bid":"ask",
			obj_data["q"] #qty
		]

		trade_obj = { :price => obj_data["p"].to_f, :time => trade_time.to_i, :event => event_time.to_i, :qty => obj_data["q"].to_f, :bull => bull }
		$rec_trade.record( trade_obj )
		update_candle( trade_obj ) if !$record_only

		f_val = obj_data["q"].to_f
		if true then
			#if f_val>=0.002 then
			message = message + " " + "X"*f_val.to_i
			if bull then
				$log.info message.cyan
			else
				$log.info message.red
			end
			# new_order( # evt vl qty
			# 	(event_time/1000.0),
			# 	obj_data["p"].to_f,
			# 	(obj_data["m"] ? 1: -1) * obj_data["q"].to_f
			# )
		end
	end


	def btcusdt_depth5( obj )
		s_local = $s_local.to_f + $diff
		obj_data	= obj["data"]
		event_time	= obj_data["E"]
		trade_time	= obj_data["T"]
		#binding.pry
		message		= " %s -> %s [%3.2fms] : %.2f - %.2f" %
		[
			format_time( event_time ),
			format_time( trade_time ),
			(s_local*1000-event_time),
			obj_data["b"].first[0],  # specific for future
			obj_data["a"].first[0]  # specific for future
		]
		$log.info message.yellow
	end




	def orderTradeUpdate( obj )
		event_time = obj["E"]
		trade_time = obj["T"]
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
		$log.info message.yellow
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
				$log.info message.yellow
			end
		}
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
