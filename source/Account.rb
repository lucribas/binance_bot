

class Account
	def update()
		$bin = {}
		puts "="*60

		puts "balance:"
		$bin[:balance] = $future_rest.balance
		puts $bin[:balance].inspect

		# not worked
		# puts "user_trades:"
		# $bin[:user_trades] = $future_rest.user_trades symbol: 'BTCUSDT'
		# puts $bin[:user_trades].inspect

		# not worked
		# puts "my_trades:"
		# $bin[:my_trades] = $future_rest.my_trades symbol: 'BTCUSDT'
		# puts $bin[:my_trades].inspect

		puts "all_orders:"
		$bin[:all_orders] = $future_rest.all_orders symbol: 'BTCUSDT'
		puts $bin[:all_orders].inspect

		puts "open_orders:"
		$bin[:open_orders] = $future_rest.open_orders symbol: 'BTCUSDT'
		puts $bin[:open_orders].inspect

		puts "account_info:"
		$bin[:account_info] = $future_rest.account_info
		puts $bin[:account_info].inspect

		puts "="*60
	end
end
