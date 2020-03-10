#------------------------------------------------------------------------------
#-- FILE NAME    : TradenerService.rb
#-- TITLE        :
#-- PROJECT      :
#-- AUTHOR       : lus
#-- PURPOSE      :
#-- NOTES        :
#-------------------------------------------------------------------------------
require 'colorize'
require 'binance'
require 'eventmachine'
require 'pry'
require 'json'
require 'bigdecimal'
require 'cli'

# telegram and binance keys
require_relative 'secret_keys'

require_relative 'lib/defines'
require_relative 'lib/Logger'
require_relative 'lib/Utils'
require_relative 'lib/Account'
require_relative 'lib/Trade'
require_relative 'lib/execute_operations'

# current timestamp
$timestamp = Time.new.strftime("%Y%m%d_%H%M%S")

# Logger
$log = Logger.new( filename: LOG_SRV_PREFIX + $timestamp + LOG_EXTENSION, fileout_en: true, stdout_en: true)

BIN_CMD = "ruby tradener.rb"

begin

	$pid = nil
	$time = Time.new
	$timestamp = $time.strftime("%Y%m%d_%H%M%S")

	STDOUT.sync = true
	$log.info "Preparing to start Daemon"


	begin
		while true
			$log.info "Service is running"
			# 1 year of timeout
			result, $has_error, force, $pid =  non_blocking_operation("Binance", "#{BIN_CMD}", 365*24*3600)
			#sleep 30
			#blocking_operation("Check BIN", "#{BIN_CHK_CMD}")
		end

		if false
			$log.info "Service stopped"
			$log.info "killing BIN"
			Process.kill 9, $pid if not $pid.nil?
			exit!
		end
	end

rescue Exception => err
	$log.error " ***Daemon failure err=#{err} "
	raise
end
