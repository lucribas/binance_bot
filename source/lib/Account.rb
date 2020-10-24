require_relative 'Logger'

class Account
	def update()
		$bin = {}
		$log_mon.info "="*60

		$log_mon.info "balance:"
		$bin[:balance] = $future_rest.balance
		$log_mon.info $bin[:balance].inspect

		# not worked
		# $log_mon.info "user_trades:"
		# $bin[:user_trades] = $future_rest.user_trades symbol: 'BTCUSDT'
		# $log_mon.info $bin[:user_trades].inspect

		# not worked
		# $log_mon.info "my_trades:"
		# $bin[:my_trades] = $future_rest.my_trades symbol: 'BTCUSDT'
		# $log_mon.info $bin[:my_trades].inspect

		$log_mon.info "all_orders:"
		$bin[:all_orders] = $future_rest.all_orders symbol: 'BTCUSDT'
		$log_mon.info $bin[:all_orders].inspect

		$log_mon.info "open_orders:"
		$bin[:open_orders] = $future_rest.open_orders symbol: 'BTCUSDT'
		$log_mon.info $bin[:open_orders].inspect

		$log_mon.info "account_info:"
		$bin[:account_info] = $future_rest.account_info
		$log_mon.info $bin[:account_info].inspect

		$log_mon.info "="*60
	end
end
