
require 'net/ntp'


def get_diff( ntp_srv )
	puts ntp_srv
	Net::NTP.get(ntp_srv)
	ntp = Net::NTP.get.time

	local = Time.now
	puts local.to_s
	puts ntp.to_s
end

puts "Testing current time:"
get_diff("a.st1.ntp.br")
puts "--"
get_diff("bigmaster.certi.org")
