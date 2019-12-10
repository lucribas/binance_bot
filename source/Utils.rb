
def format_time( evt_time )
	evt = (evt_time.to_f/1000)
	evt = evt.to_f-evt.to_i
	return "%s (%.3fms)" %
	[	Time.at(evt_time/1000).to_s,
		evt	]
end



def sformat_time( evt_time )
	return Time.at(evt_time/1000).to_s
end



def print_trade( trade_obj )
	return if $log.log_en?
	event_time	= trade_obj[:event]
	trade_time	= trade_obj[:time]
	bull		= trade_obj[:bull]
	message		= " %s -> %s [%3.2fms] : %.2f (%s) - %.6f" %
	[
		format_time( event_time ),
		format_time( trade_time ),
		(0.0),
		trade_obj[:price],
		bull ? "bid" : "ask",
		trade_obj[:qty]
	]
	f_val = trade_obj[:qty].to_f
	message = message + " " + "X"*f_val.to_i
	if bull then
		$log.info message.cyan
	else
		$log.info message.red
	end
end



def sent_telegram( message )
	Telegram::Bot::Client.run($telegram_token) do |bot|
		bot.api.send_message( chat_id: 43716964, text: message)
	end
end


def send_trade_info( message )
	$message_buffer = $message_buffer + message + "\n"
end

def send_trade_info_send
	$trade.info $message_buffer
	sent_telegram $message_buffer if $telegram_en
	$message_buffer = ""
end


def ntp_test()
	# binding.pry
	$log.info "-"*30
	$log.info "Calibrating current time against NTP server:"
	Net::NTP.get("a.st1.ntp.br")
	#cache
	ntp = Net::NTP.get.time
	ntp = Net::NTP.get.time
	ntp = Net::NTP.get.time
	local = Time.now
	local = Time.now
	local = Time.now
	ntp = Net::NTP.get.time
	#run
	tot_diff = 0
	num = 5
	for i in 1..num do
		ntp = Net::NTP.get.time
		local = Time.now
		#$log.info "local= #{local.to_s}"
		#$log.info "ntp=   #{ntp.to_s}"
		diff = ntp.to_f-local.to_f
		#$log.info "diff = [%.6fs]" % [(diff)]
		tot_diff = tot_diff + diff
	end
	diff = tot_diff/num
	$log.info "diff_mean (num=%d) = [%.5fms]" % [ num, diff*1000]
	return diff
end

def binance_latence(diff: 0, num: 5)
	$log.info "-"*60
	$log.info "Checking difference latecy to Binance server"
	$log.info "|  diff   |         Local time          |         Binance Server"
	tot_diff = 0
	for i in 1..num do
		bin_time = $future_rest.time["serverTime"]
		s_local = Time.now
		s_local = s_local.to_f + diff
		bin_diff = s_local*1000-bin_time
		$log.info "[%.2fms]\t%s\t%s" % [(bin_diff), Time.at(s_local), Time.at(bin_time/1000) ]
		tot_diff = tot_diff + bin_diff
	end
	$log.info "diff_mean (num=%d) = [%.2fms]" % [ num, tot_diff/num ]
	$log.info "-"*60
	return (tot_diff/num)/1000
end
