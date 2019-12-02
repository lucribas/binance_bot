
require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'net/ntp'

require_relative 'secret_keys'

def ntp_test()
	# binding.pry
	puts "-"*30
	puts "Calibrating current time against NTP server:"
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
		#puts "local= #{local.to_s}"
		#puts "ntp=   #{ntp.to_s}"
		diff = ntp.to_f-local.to_f
		#puts "diff = [%.6fs]" % [(diff)]
		tot_diff = tot_diff + diff
	end
	diff = tot_diff/num
	puts "diff_mean (num=%d) = [%.5fms]" % [ num, diff*1000]
	return diff
end

def binance_latence(rest, diff)
	puts "-"*30
	puts "Checking difference latecy to Binance server"
	tot_diff = 0
	num = 3
	for i in 1..num do
		bin_time = rest.time["serverTime"]
		s_local = Time.now
		s_local = s_local.to_f + diff
		bin_diff = s_local*1000-bin_time
		#puts "[%.2fms]  %s  %s" % [(bin_diff), Time.at(s_local), Time.at(bin_time/1000) ]
		tot_diff = tot_diff + bin_diff
	end
	puts "diff_mean (num=%d) = [%.2fms]" % [ num, tot_diff/num ]
end

rest  = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
ws    = Binance::Client::WebSocket.new

#diff = ntp_test
#binance_latence(rest, diff)

binding.pry
