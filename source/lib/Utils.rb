




def ntp_test(diff: 0, num: 5)
	# binding.pry
	$log_mon.info "-"*30
	$log_mon.info "Calibrating current time against NTP server:"
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
	for i in 1..num do
		ntp = Net::NTP.get.time
		local = Time.now
		$log_mon.info "local= #{local.to_s}"
		$log_mon.info "ntp=   #{ntp.to_s}"
		diff = ntp.to_f-local.to_f
		$log_mon.info "diff = [%.6fs]" % [(diff)]
		tot_diff = tot_diff + diff
	end
	diff = tot_diff/num
	$log_mon.info "diff_mean (num=%d) = [%.5fms]" % [ num, diff*1000]
	return diff
end

def binance_latency(diff: 0, num: 5)
	$log_mon.info "-"*60
	$log_mon.info "Checking difference latecy to Binance server"
	$log_mon.info "|  diff   |         Local time          |         Binance Server"
	tot_diff = 0
	for i in 1..num do
		bin_time = $future_rest.time["serverTime"]
		s_local = Time.now
		s_local = s_local.to_f + diff
		bin_diff = s_local*1000-bin_time
		$log_mon.info "[%.2fms]\t%s\t%s" % [(bin_diff), Time.at(s_local), Time.at(bin_time/1000) ]
		tot_diff = tot_diff + bin_diff
	end
	$log_mon.info "diff_mean (num=%d) = [%.2fms]" % [ num, tot_diff/num ]
	$log_mon.info "-"*60
	return (tot_diff/num)/1000
end
