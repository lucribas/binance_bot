
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
