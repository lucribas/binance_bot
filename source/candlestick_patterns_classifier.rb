# based on
# https:#www.mql5.com/pt/articles/101
#


# posso usar os padroes abaixo para alimentar um ML mais tarde






#+------------------------------------------------------------------+
#|   Function of determining of candlestick                         |
#+------------------------------------------------------------------+


def pattern( candle, position )

	result = nil

	c1	= candle[position]

	# puts c1.inspect
	# binding.pry

	## Check patterns on one candlestick */

			#------
			# Inverted Hammer, the Bull
			if ( c1[:trend]==:BEAR and # check direction of trend
				c1[:type]==:CAND_INVERT_HAMMER) then # the "Inverted Hammer" check
				result	= { com: "Inverted Hammer (Bull)", figure: :INV_HAMMER_BULL}
			end
			# Hammer, the Bull
			if ( c1[:trend]==:BEAR and # check direction of trend
				c1[:type]==:CAND_HAMMER) then # the "Hammer" check
				result	= { com: "Hammer (Bull)", figure: :INV_HAMMER_BULL}
			end

			# Hanging Man, the Bear
			if ( c1[:trend]==:BULL and # check direction of trend
				c1[:type]==:CAND_HAMMER) then # the "Hammer" check
				result	= { com: "Hanging Man (Bear)", figure: :HAMMER_BEAR}
			end
			# Inverted Hammer, the Bear
			if ( c1[:trend]==:BULL and # check direction of trend
				c1[:type]==:CAND_INVERT_HAMMER) then # the "Inverted Hammer" check
				result	= { com: "Inverted Hammer (Bear)", figure: :INV_HAMMER_BEAR}
			end

			#------

	## Check of patters with two candlesticks */

			c2	= candle[position]
			c1	= candle[position-1]

			#------
			# Shooting Star, the Bear
			if ( c1[:trend]==:BULL and c2[:trend]==:BULL and # check direction of trend
				c2[:type]==:CAND_INVERT_HAMMER) then # the "Inverted Hammer" check

				result	= { com: "Shooting Star (Bear)", figure: :SHOOTING_STAR_BEAR}

				# if ( c1[:close]<=c2[:open]) # close 1 is less than or equal to open 1
				# 		comment2="Shooting Star the Bear"
				# else
				# 	if ( c1[:close]<c2[:open] and c1[:close]<c2[:close]) # 2 candlestick is cut off from 1
				# 		comment2="Shooting Star the Bear"
			end

			# ------
			# Belt Hold, the bullish
			if ( c2[:trend]==:BEAR and c2[:bull] and !c1[:bull] and # check direction of trend and direction of candlestick
				c2[:type]==:CAND_MARIBOZU_LONG and # the "long Maribozu" check
				c1[:bodysize]<c2[:bodysize] and c2[:close]<c1[:close]) then # body of the first candlestick is smaller than body of the second one, close price of the second candlestick is lower than the close price of the first one
				result	= { com: "Belt Hold (Bull)", figure: :BELT_HOLD_BULL}
			end

			# Belt Hold, the Bear
			if ( c2[:trend]==:BULL and !c2[:bull] and c1[:bull] and # check direction of trend and direction of candlestick
				c2[:type]==:CAND_MARIBOZU_LONG and # the "long Maribozu" check
				c1[:bodysize]<c2[:bodysize] and c2[:close]>c1[:close]) then # body of the first candlestick is lower than body of the second one; close price of the second candlestick is higher than that of the first one
				result	= { com: "Belt Hold (Bear)", figure: :BELT_HOLD_BEAR}
			end

			#------
			# Engulfing, the Bull
			if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:trend]==:BEAR and c2[:bull] and # check direction of trend and direction of candlestick
				c1[:bodysize]<c2[:bodysize]) then # body of the third candlestick is bigger than that of the second one
				# result	= { com: "Engulfing (Bull)", figure: :ENGULFING_BULL}
				if ( c1[:close]>=c2[:open] and c1[:open]<c2[:close]) then # body of the first candlestick is inside of body of the second one
						result	= { com: "Engulfing (Bull)", figure: :ENGULFING_BULL}
				end
			end

			# Engulfing, the Bear
			if ( c1[:trend]==:BULL and c1[:bull] and c2[:trend]==:BULL and !c2[:bull] and # check direction and direction of candlestick
				c1[:bodysize]<c2[:bodysize]) then # body of the third candlestick is bigger than that of the second one
				# result	= { com: "Engulfing (Bear)", figure: :ENGULFING_BEAR}
				if ( c1[:close]<=c2[:open] and c1[:open]>c2[:close]) then # body of the first candlestick is inside of body of the second one
						result	= { com: "Engulfing (Bear)", figure: :ENGULFING_BEAR}
				end
			end

			#------
			# Harami Cross, the Bull
			if ( c1[:trend]==:BEAR and !c1[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and c2[:type]==:CAND_DOJI) then # check of "long" first candlestick and Doji candlestick
				# result	= { com: "Harami Cross (Bull)"}
				if ( c1[:close]<=c2[:open] and c1[:close]<=c2[:close] and c1[:open]>c2[:close]) then # Doji is inside of body of the first candlestick
						result	= { com: "Harami Cross (Bull)", figure: :HARAMI_CROSS_BULL}
				end
			end
			# Harami Cross, the Bear
			if ( c1[:trend]==:BULL and c1[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and c2[:type]==:CAND_DOJI) then # check of "long" candlestick and Doji
				# result	= { com: "Harami Cross (Bear)"}
				if ( c1[:close]>=c2[:open] and c1[:close]>=c2[:close] and c1[:close]>=c2[:close]) then # Doji is inside of body of the first candlestick
						result	= { com: "Harami Cross (Bear)", figure: :HARAMI_CROSS_BEAR}
				end
			end
			#------
			# Harami, the Bull
			if ( c1[:trend]==:BEAR  and  !c1[:bull]  and  c2[:bull] and# check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and  # check of "long" first candlestick
				c2[:type]!=:CAND_DOJI and c1[:bodysize]>c2[:bodysize]) # the second candlestick is not Doji and body of the first candlestick is bigger than that of the second one
				# result	= { com: "Harami (Bull)"}
				if ( c1[:close]<=c2[:open] and c1[:close]<=c2[:close] and c1[:open]>c2[:close]) then # body of the second candlestick is inside of body of the first candlestick
						result	= { com: "Harami (Bull)", figure: :HARAMI_BULL}
				end
			end
			# Harami, the Bear
			if ( c1[:trend]==:BULL and c1[:bull] and !c2[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # check of "long" first candlestick
				c2[:type]!=:CAND_DOJI and c1[:bodysize]>c2[:bodysize]) then # the second candlestick is not Doji and body of the first candlestick is bigger than that of the second one
				# result	= { com: "Harami (Bear)"}
				if ( c1[:close]>=c2[:open] and c1[:close]>=c2[:close] and c1[:close]>=c2[:close]) then # Doji is inside of body of the first candlestick
						result	= { com: "Harami (Bear)", figure: :HARAMI_BEAR}
				end
			end
			#------
			# Doji Star, the Bull
			if ( c1[:trend]==:BEAR and !c1[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and c2[:type]==:CAND_DOJI) then # check first "long" candlestick and 2 doji
				# result	= { com: "Doji Star the Bull", figure: :DOJI_STAR_BULL}
				if ( c1[:close]>=c2[:open]) then # Open price of Doji is lower or equal to close price of the first candlestick
					result	= { com: "Doji Star the Bull", figure: :DOJI_STAR_BULL}
				elsif ( c1[:close]>c2[:open] and c1[:close]>c2[:close]) then # Body of Doji is cut off the body of the first candlestick
					result	= { com: "Doji Star the Bull", figure: :DOJI_STAR_BULL}
				end
			end

			# Doji Star, the Bear
			if ( c1[:trend]==:BULL and c1[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and c2[:type]==:CAND_DOJI) then # check first "long" candlestick and 2 doji
				# result	= { com: "Doji Star (Bear)"}
				if ( c1[:close]<=c2[:open]) then # # open price of Doji is higher or equal to close price of the first candlestick
					result	= { com: "Doji Star the Bear", figure: :DOJI_STAR_BEAR}
				elsif ( c1[:close]<c2[:open] and c1[:close]<c2[:close]) # # body of Doji is cut off the body of the first candlestick
					result	= { com: "Doji Star the Bear", figure: :DOJI_STAR_BEAR}
				end
			end

			#------
			# Piercing Line, the Bull
			if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:trend]==:BEAR and c2[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
				c2[:close]>(c1[:close]+c1[:open])/2) then # close price of the second candle is higher than the middle of the first one
				if ( c1[:close]>=c2[:open] and c2[:close]<=c1[:open]) then
					result	= { com: "Piercing Line (Bull)", figure: :PIERCING_LINE_BULL}
				elsif ( c2[:open]<c1[:low] and c2[:close]<=c1[:open]) then # open price of the second candle is lower than LOW price of the first one
					result	= { com: "Piercing Line (Bull)", figure: :PIERCING_LINE_BULL}
				end
			end
			# Dark Cloud Cover, the Bear
			if ( c1[:trend]==:BULL and c1[:bull] and c2[:trend]==:BULL and !c2[:bull] and # check direction and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
				c2[:close]<(c1[:close]+c1[:open])/2) then # close price of 2-nd candlestick is lower than the middle of the body of the 1-st one
				if ( c1[:close]<=c2[:open] and c2[:close]>=c1[:open]) then
					result	= { com: "Dark Cloud Cover (Bear)", figure: :DARK_CLOUD_COVER_BEAR}
				elsif ( c1[:high]<c2[:open] and c2[:close]>=c1[:open])
					result	= { com: "Dark Cloud Cover (Bear)", figure: :DARK_CLOUD_COVER_BEAR}
				end
			end

			#------
			# Meeting Lines the Bull /
			if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:trend]==:BEAR and c2[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
				c1[:close]==c2[:close] and c1[:bodysize]<c2[:bodysize] and c1[:low]>c2[:open]) then # close prices are equal, size of the first candlestick is smaller than that of the second one; open price of the second one is lower than minimum of the first one
				result	= { com: "Meeting Lines (Bull)", figure: :MEETING_LINES_BULL}
			end

			# Meeting Lines, the Bear
			if ( c1[:trend]==:BULL and c1[:bull] and c2[:trend]==:BULL and !c2[:bull] and # check direction and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
				c1[:close]==c2[:close] and c1[:bodysize]<c2[:bodysize] and c1[:high]<c2[:open]) then # # close prices are equal, size of the first one is smaller than that of the second one, open price of the second one is higher than the maximum of the first one
				result	= { com: "Meeting Lines (Bear)", figure: :MEETING_LINES_BEAR}
			end

			#------
			# Matching Low, the Bull
			if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:trend]==:BEAR and !c2[:bull] and # check direction of trend and direction of candlestick
				c1[:close]==c2[:close] and c1[:bodysize]>c2[:bodysize]) then # close price are equal, size of the first one is greater than that of the second one
				result	= { com: "Matching Low (Bull)", figure: :MATCHING_LOW_BULL}
			end
			#------
			# Homing Pigeon, the Bull
			if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:trend]==:BEAR and !c2[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
				c1[:close]<c2[:close]  and  c1[:open]>c2[:open]) then # body of the second candlestick is inside of body of the first one
				result	= { com: "Homing Pigeon (Bull)", figure: :HOMING_PIGEON_BULL}
			end

	## Continuation Models */

			#------
			# Kicking, the Bull
			if ( !c1[:bull] and c2[:bull] and # check direction of trend and direction of candlestick
				c1[:type]==:CAND_MARIBOZU_LONG and c2[:type]==:CAND_MARIBOZU_LONG and # two maribozu
				c1[:open]<c2[:open]) then # gap between them
				result	= { com: "Kicking (Bull)", figure: :KICKING_BULL}
			end
			# Kicking, the Bear
			if ( c1[:bull] and !c2[:bull] and # check direction of trend and direction of candlestick
				c1[:type]==:CAND_MARIBOZU_LONG and c2[:type]==:CAND_MARIBOZU_LONG and # two maribozu
				c1[:open]>c2[:open]) then # gap between them
				result	= { com: "Kicking (Bear)", figure: :KICKING_BEAR}
			end
			#------ Check of module of the neck line
			if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:bull] and # check direction of trend and direction of candlestick
				(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG)) then # first candlesticks is "long"
					# On Neck Line, the Bear
					if ( c2[:open]<c1[:low] and c2[:close]==c1[:low]) then # second candlestick is opened below the first one and is closed at the minimum level of the first one
						result	= { com: "On Neck Line (Bear)", figure: :ON_NECK_LINE_BEAR}
					else
						# In Neck Line, the Bear
						if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:bull] and # check direction of trend and direction of candlestick
								(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # first candlestick is "long"
								c1[:bodysize]>c2[:bodysize] and # body of the second candlestick is smaller than body of the first one
								c2[:open]<c1[:low] and c2[:close]>=c1[:close] and c2[:close]<(c1[:close]+c1[:bodysize]*0.01)) then # second candlestick is opened below the first one and is closed slightly higher the closing of the first one
									result	= { com: "In Neck Line (Bear)", figure: :IN_NECK_LINE_BEAR}
						else
								# Thrusting Line, the Bear
								if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:bull] and # check direction of trend and direction of candlestick
								(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # first candlestick is "long"
								c2[:open]<c1[:low] and c2[:close]>c1[:close] and c2[:close]<(c1[:open]+c1[:close])/2) then # the second candlestick is opened below the first one and is closed above the closing of the first one, bu below its middle
									result	= { com: "Thrusting Line (Bear)", figure: :THRUSTING_LINE_BEAR}
								end
						end
					end
			end

			if !result.nil? then
				puts "=="*30
				puts result.inspect
				puts "=="*30
			end

	return result
end
	#
	# ## Check of patterns with three candlesticks */
	#
	# 		c3	= candle[position]
	# 		c2	= candle[position-1]
	# 		c1	= candle[position-2]
	#
	# 		if ( !RecognizeCandle(_Symbol,_Period,time[i-2],InpPeriodSMA,c1))
	# 			continue;
	# 		#------
	# 		# The Abandoned Baby, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and c3[:trend]==:BEAR and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c2[:type]==:CAND_DOJI and # check if the second candlestick is Doji
	# 			c3[:close]<c1[:open] and c3[:close]>c1[:close]) # the third one is closed inside of body of the first one
	# 			result	= { com: "Abandoned Baby (Bull)"}
	# 			if ( c1[:low]>c2[:high] and c3[:low]>c2[:high]) # gap between candlesticks
	# 					comment2="Abandoned Baby the Bull"
	# 		# The Abandoned Baby, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c3[:trend]==:BULL and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c2[:type]==:CAND_DOJI and # check if the second candlestick is Doji
	# 			c3[:close]>c1[:open] and c3[:close]<c1[:close]) # # the third one is closed inside of body of the second one
	# 			result	= { com: "Abandoned Baby (Bear)"}
	# 			if ( c1[:high]<c2[:low] and c3[:high]<c2[:low]) # gap between candlesticks
	# 					comment2="Abandoned Baby the Bear"
	# 		# ------
	# 		# Morning star, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and c3[:trend]==:BEAR and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c2[:type]==:CAND_SHORT and # check of "short" candlestick
	# 			c3[:close]>c1[:close] and c3[:close]<c1[:open]) # the third candlestick is closed inside of body of the first one
	# 			result	= { com: "Morning Star (Bull)"}
	# 			if ( c2[:open]<=c1[:close]) # Open price of the second candlestick is lower than the closing of the first one
	# 					comment2="Morning star the Bull"
	# 			else # other market
	# 			if ( c2[:open]<c1[:close] and c2[:close]<c1[:close]) # distance from the second candlestick to the first one
	# 					comment2="Morning star the Bull"
	# 		# Evening star, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c3[:trend]==:BULL and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c2[:type]==:CAND_SHORT and # check of "short" candlestick
	# 			c3[:close]<c1[:close] and c3[:close]>c1[:open]) # the third candlestick is closed inside of body of the first one
	# 			result	= { com: "Evening Star (Bear)"}
	# 			if ( c2[:open]>=c1[:close]) # open price of the second candlestick is higher than that of the first one
	# 					comment2="Evening star the Bear"
	# 			else # other market
	# 			if ( c2[:open]>c1[:close] and c2[:close]>c1[:close]) # gap between candlesticks
	# 					comment2="Evening star the Bear"
	# 		#------
	# 		# Morning Doji Star, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and c3[:trend]==:BEAR and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c2[:type]==:CAND_DOJI and # check of "doji"
	# 			c3[:close]>c1[:close] and c3[:close]<c1[:open]) # the third candlestick is closed inside of body of the first one
	# 			result	= { com: "Morning Doji Star (Bull)"}
	# 			if ( c2[:open]<=c1[:close]) # open price of Doji is lower or equal to the close price of the first candlestick
	# 					comment2="Morning Doji Star the Bull"
	# 			else # other market
	# 			if ( c2[:open]<c1[:close]) # gap between Doji and the first candlestick
	# 					comment2="Morning Doji Star the Bull"
	# 		# Evening Doji Star, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c3[:trend]==:BULL and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c2[:type]==:CAND_DOJI and # check of "doji"
	# 			c3[:close]<c1[:close] and c3[:close]>c1[:open]) # the third candlestick is closed inside of body of the first one
	# 			result	= { com: "Evening Doji Start (Bear)"}
	# 			if ( c2[:open]>=c1[:close]) # open price of Doji is higher or equal to close price of the first candlestick
	# 					comment2="Evening Doji Star the Bear"
	# 			else # other market
	# 			if ( c2[:open]>c1[:close]) # gap between Doji and the first candlestick
	# 					# check of close 2 and open 3
	# 					comment2="Evening Doji Star the Bear"
	# 		#------
	# 		# Upside Gap Two Crows, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:trend]==:BULL and !c2[:bull] and c3[:trend]==:BULL and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG)  and  # check of "long" candlestick
	# 			c1[:close]<c2[:close] and c1[:close]<c3[:close] and # distance of the second and third candlesticks from the first one
	# 			c2[:open]<c3[:open] and c2[:close]>c3[:close]) # the third candlestick absorbs the second one
	# 			result	= { com: "Upside Gap Two Crows (Bear)"}
	# 		#------
	# 		# Two Crows, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:trend]==:BULL and !c2[:bull] and c3[:trend]==:BULL and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONGor c1[:type]==:CAND_MARIBOZU_LONG) and(c3[:type]==:CAND_LONGor c3[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			c1[:close]<c2[:close] and # distance between the second and first candlesticks
	# 			c3[:open]>c2[:close] and # the third candlestick is opened higher than the close price of the second one
	# 			c3[:close]<c1[:close]) # the third candlestick is closed below the close price of the first one
	# 			result	= { com: "Two Crows (Bear)"}
	# 		#------
	# 		# Three Star in the South, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c3[:type]==:CAND_MARIBOZU or c3[:type]==:CAND_SHORT) and # check of "long" candlestick and "maribozu"
	# 			c1[:bodysize]>c2[:bodysize] and c1[:low]<c2[:low] and c3[:low]>c2[:low] and c3[:high]<c2[:high])
	# 			result	= { com: "Three Star in the South (Bull)"}
	# 			else # other market
	# 			if ( c1[:close]<c2[:open] and c2[:close]<c3[:open]) # opening inside the previous candlestick
	# 					comment2="Three Star in the South the Bull"
	# 		# Deliberation, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick
	# 			(c3[:type]==:CAND_SPIN_TOP or c3[:type]==:CAND_SHORT)) # the third candlestick is the spin or start
	# 			result	= { com: "Deliberation (Bear)"}
	# 			else # other market
	# 			if ( c1[:close]>c2[:open] and c2[:close]<=c3[:open]) # opening inside the previous candlestick
	# 					# check of close 2 and open 3
	# 					comment2="Deliberation the Bear"
	# 		#------
	# 		# Three White Soldiers, the Bull
	# 		if ( c1[:trend]==:BEAR and c1[:bull] and c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick or "maribozu"
	# 			(c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG)) # check of "long" candlestick and "maribozi"
	# 			result	= { com: "Three White Soldiers (Bull)"}
	# 			else # other market
	# 			if ( c1[:close]>c2[:open] and c2[:close]>c3[:open]) # opening inside the previous candlestick
	# 					comment2="Three White Soldiers the Bull"
	# 		# Three Black Crows, the Bear
	# 		if ( c1[:trend]==:BULL and !c1[:bull] and !c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick or "maribozu"
	# 			(c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check "long" candlestick and "maribozu"
	# 			c1[:close]<c2[:open]  and  c2[:close]<c3[:open]) # opening inside the previous candlestick
	# 			result	= { com: "Three Black Crows (Bear)"}
	# 		#------
	# 		# Three Outside Up, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:trend]==:BEAR and c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			c2[:bodysize]>c1[:bodysize] and # body of the second candlestick is bigger than that of the first one
	# 			c3[:close]>c2[:close]) # the third day is closed higher than the second one
	# 			result	= { com: "Three Outside Up (Bull)"}
	# 			if ( c1[:close]>=c2[:open] and c1[:open]<c2[:close]) # body of the first candlestick is inside of body of the second one
	# 					comment2="Three Outside Up the Bull"
	# 			else
	# 			if ( c1[:close]>c2[:open] and c1[:open]<c2[:close]) # body of the first candlestick inside of body of the second candlestick
	# 					comment2="Three Outside Up the Bull"
	# 		# Three Outside Down, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:trend]==:BULL and !c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			c2[:bodysize]>c1[:bodysize] and # body of the second candlestick is bigger than that of the first one
	# 			c3[:close]<c2[:close]) # the third day is closed lower than the second one
	# 			result	= { com: "Three Outside Down (Bear)"}
	# 			if ( c1[:close]<=c2[:open] and c1[:open]>c2[:close]) # body of the first candlestick is inside of body of the second one
	# 					comment2="Three Outside Down the Bear"
	# 			else
	# 			if ( c1[:close]<c2[:open] and c1[:open]>c2[:close]) # body of the first candlestick is inside of body of the second one
	# 					comment2="Three Outside Down the Bear"
	# 		#------
	# 		# Three Inside Up, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # check of "long" first candle
	# 			c1[:bodysize]>c2[:bodysize] and # body of the first candlestick is bigger than that of the second one
	# 			c3[:close]>c2[:close]) # the third day is closed higher than the second one
	# 			result	= { com: "Three Inside Up (Bull)"}
	# 			if ( c1[:close]<=c2[:open] and c1[:close]<=c2[:close] and c1[:open]>c2[:close]) # body of the second candlestick is inside of body of the first candlestick
	# 					comment2="Three Inside Up the Bull"
	# 			else
	# 			if ( c1[:close]<c2[:open] and c1[:close]<c2[:close] and c1[:open]>c2[:close]) # body of the second candlestick is inside of body of the first one
	# 					comment2="Three Inside Up the Bull"
	# 		# Three Inside Down, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and !c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and # check of "long" first candle
	# 			c1[:bodysize]>c2[:bodysize] and # body of the first candlestick is bigger than that of the second one
	# 			c3[:close]<c2[:close]) # the third day is closed lower than the second one
	# 			result	= { com: "Three Inside Down (Bear)"}
	# 			if ( c1[:close]>=c2[:open] and c1[:close]>=c2[:close] and c1[:close]>=c2[:close]) # inside of body of the first candlestick
	# 					comment2="Three Inside Down the Bear"
	# 			else
	# 			if ( c1[:close]>c2[:open] and c1[:close]>c2[:close] and c1[:open]<c2[:close]) # inside of body of the first candlestick
	# 					comment2="Three Inside Down the Bear"
	# 		#------
	# 		# Tri Star, the Bull
	# 		if ( c1[:trend]==:BEAR and # check direction of trend
	# 			c1[:type]==:CAND_DOJI and c2[:type]==:CAND_DOJI and c3[:type]==:CAND_DOJI) # check of Doji
	# 			result	= { com: "Tri Star (Bull)"}
	# 			else
	# 			if ( c2[:open]!=c1[:close] and c2[:close]!=c3[:open]) # the second candlestick is on the other level
	# 					comment2="Tri Star the Bull"
	# 		# Tri Star, the Bear
	# 		if ( c1[:trend]==:BULL and # check direction of trend
	# 			c1[:type]==:CAND_DOJI and c2[:type]==:CAND_DOJI and c3[:type]==:CAND_DOJI) # check of Doji
	# 			result	= { com: "Tri Star (Bear)"}
	# 			else
	# 			if ( c2[:open]!=c1[:close] and c2[:close]!=c3[:open]) # the second candlestick is on the other level
	# 					comment2="Tri Star the Bear"
	# 		#------
	# 		# Identical Three Crows, the Bear
	# 		if ( c1[:trend]==:BULL and !c1[:bull] and !c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick or "maribozu"
	# 			(c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG)) # check of "long" candlestick and "maribozi"
	# 			result	= { com: "Identical Three Crows (Bear)"}
	# 			else # other market
	# 			if ( c1[:close]>=c2[:open] and c2[:close]>=c3[:open]) # open price is smaller or equal to close price of the previous candlestick
	# 					comment2="Identical Three Crows the Bear"
	# 		#------
	# 		# Unique Three River Bottom, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and c3[:type]==:CAND_SHORT and # check of "long" candlestick or "maribozu" or the third day is short
	# 			c2[:open]<c1[:open] and c2[:close]>c1[:close] and c2[:low]<c1[:low] and # body of the second candlestick is inside the first one, and its minimum is lower than the first one
	# 			c3[:close]<c2[:close]) # the third candlestick is lower than the second one
	# 			result	= { com: "Unique Three River Bottom (Bull)"}
	#
	# ## Continuation Models */
	#
	# 		#------
	# 		# Upside Gap Three Methods, the Bull
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # the first two candles are "long"
	# 			c2[:open]>c1[:close] and # gap between the second and first candlesticks
	# 			c3[:open]>c2[:open] and c3[:open]<c2[:close] and c3[:close]<c1[:close]) # the third candlestick is opened inside the second one and it fills the gap
	# 			result	= { com: "Upside Gap Three Methods (Bull)"}
	# 		#------
	# 		# Downside Gap Three Methods, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # the first two candles are "long"
	# 			c2[:open]<c1[:close] and # gap between the first and second candlesticks
	# 			c3[:open]<c2[:open] and c3[:open]>c2[:close] and c3[:close]>c1[:close]) # the third candlestick is opened inside the second one and fills the gap
	# 			result	= { com: "Downside Gap Three Methods (Bear)"}
	# 		#------
	# 		# Upside Tasuki Gap, the Bull
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:bull] and !c3[:bull] and # check direction of trend and direction of candlestick
	# 			c1[:type]!=:CAND_DOJI and c2[:type]!=:CAND_DOJI and # the first two candlesticks are not Doji
	# 			c2[:open]>c1[:close] and # gap between the second and first candlesticks
	# 			c3[:open]>c2[:open] and c3[:open]<c2[:close] and c3[:close]<c2[:open] and c3[:close]>c1[:close]) # the third candlestick is opened inside the second one and is closed inside the gap
	# 			result	= { com: "Upside Tasuki Gap (Bull)"}
	# 		#------
	# 		# Downside Tasuki Gap, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and c3[:bull] and # check direction of trend and direction of candlestick
	# 			c1[:type]!=:CAND_DOJI and c2[:type]!=:CAND_DOJI and # the first two candlesticks are not Doji
	# 			c2[:open]<c1[:close] and # gap between the first and second candlesticks
	# 			c3[:open]<c2[:open] and c3[:open]>c2[:close] and c3[:close]>c2[:open] and c3[:close]<c1[:close]) # the third candlestick is opened isnside the second one, and is closed within the gap
	# 			result	= { com: "Downside Tasuki Gap (Bear)"}
	#
	# ## Check of patterns with four candlesticks */
	# ## Check of patterns with four candles */
	#
	# c4	= candle[position]
	# c3	= candle[position-1]
	# c2	= candle[position-2]
	# c1	= candle[position-3]
	#
	# 		if ( !RecognizeCandle(_Symbol,_Period,time[i-3],InpPeriodSMA,c1))
	# 			continue;
	#
	# 		#------
	# 		# Concealing Baby Swallow, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and !c3[:bull] and !c4[:bull] and # check direction of trend and direction of candlestick
	# 			c1[:type]==:CAND_MARIBOZU_LONG and c2[:type]==:CAND_MARIBOZU_LONG and c3[:type]==:CAND_SHORT and # check of "maribozu"
	# 			c3[:open]<c2[:close] and c3[:high]>c2[:close] and # the third candlestick with a lower gap, maximum is inside the second candlestick
	# 			c4[:open]>c3[:high] and c4[:close]<c3[:low]) # the fourth candlestick fully consumes the third one
	# 			result	= { com: "Concealing Baby Swallow (Bull)"}
	# 		#------
	# 		# Three-line strike, the Bull
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:bull] and c3[:bull] and !c4[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick or "maribozu"
	# 			(c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check "long" candlestick and "maribozu"
	# 			c2[:close]>c1[:close] and c3[:close]>c2[:close] and c4[:close]<c1[:open]) # closing of the second candlestick is above the first one,closing of the third one is above the second one; the fourth candlestick is closed below the first one
	# 			result	= { com: "Three-line strike (Bull)"}
	# 			if ( c4[:open]>=c3[:close]) # the fourth candlestick is opened above or on the same level with the third one
	# 					comment2="Three-line strike the Bull"
	# 			else # other market
	# 			if ( c4[:open]>c3[:close]) # the fourth candlestick is opened above the third one
	# 					comment2="Three-line strike the Bull"
	# 		#------
	# 		# Three-line strike, the Bear
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and !c3[:bull] and c4[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONG or c1[:type]==:CAND_MARIBOZU_LONG) and (c2[:type]==:CAND_LONG or c2[:type]==:CAND_MARIBOZU_LONG) and # check of "long" candlestick or "maribozu"
	# 			(c3[:type]==:CAND_LONG or c3[:type]==:CAND_MARIBOZU_LONG) and # check "long" candlestick and "maribozu"
	# 			c2[:close]<c1[:close] and c3[:close]<c2[:close] and c4[:close]>c1[:open]) # closing of the second one is below the first, third is below the second, fourth is closed above the first one
	# 			result	= { com: "Three-line strike (Bear)"}
	# 			if ( c4[:open]<=c3[:close]) # the fourth candlestick is opened below or on the same level with the third one
	# 					comment2="Three-line strike the Bear"
	# 			else # other market
	# 			if ( c4[:open]<c3[:close]) # the fourth candlestick is opened below the third one
	# 					comment2="Three-line strike the Bear"
	# ## Check of patterns with five candlesticks */
	# ## Check of patterns with five candles */
	# c5	= candle[position]
	# c4	= candle[position-1]
	# c3	= candle[position-2]
	# c2	= candle[position-3]
	# c1	= candle[position-4]
	# 		if ( !RecognizeCandle(_Symbol,_Period,time[i-4],InpPeriodSMA,c1))
	# 			continue;
	#
	# 		#------
	# 		# Breakaway, the Bull
	# 		if ( c1[:trend]==:BEAR and !c1[:bull] and !c2[:bull] and !c4[:bull] and c5[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONGor c1[:type]==:CAND_MARIBOZU_LONG) and  # check of "long" first candlestick
	# 			c2[:type]==:CAND_SHORT and c2[:open]<c1[:close] and # the second "candlestick" is "short" and is cut off the first one
	# 			c3[:type]==:CAND_SHORT and c4[:type]==:CAND_SHORT and # the third and fourth candlesticks are "short"
	# 			(c5[:type]==:CAND_LONG or c5[:type]==:CAND_MARIBOZU_LONG) and c5[:close]<c1[:close] and c5[:close]>c2[:open]) # the fifth one is "long", white and is closed inside the gap
	# 			result	= { com: "Breakaway (Bull)"}
	# 		# Breakaway, the Bear
	# 		if ( c1[:trend]==:BULL and c1[:bull] and c2[:bull] and c4[:bull] and !c5[:bull] and # check direction of trend and direction of candlestick
	# 			(c1[:type]==:CAND_LONGor c1[:type]==:CAND_MARIBOZU_LONG) and  # check of "long" first candlestick
	# 			c2[:type]==:CAND_SHORT and c2[:open]<c1[:close] and # the second "candlestick" is "short" and is cut off the first one
	# 			c3[:type]==:CAND_SHORT and c4[:type]==:CAND_SHORT and # the third and fourth candlesticks are "short"
	# 			(c5[:type]==:CAND_LONG or c5[:type]==:CAND_MARIBOZU_LONG) and c5[:close]>c1[:close] and c5[:close]<c2[:open]) # the fifth candlestick is "long" and is closed inside the gap
	# 			result	= { com: "Breakaway (Bear)"}
	#
	# 		} # end of cycle of checks
