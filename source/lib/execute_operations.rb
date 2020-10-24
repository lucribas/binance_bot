require 'open3'
require 'timeout'
require_relative 'Logger'

def process_exit_status ( exit_status, msg_value, force )
	result = false
	has_error = false
	msg_value = "" if msg_value.nil?
	no_error = (exit_status != nil) ? exit_status.success? : false
	if no_error == true then
		$log.info(msg_value + "\tSUCCESS")
		result = true
	else
		if exit_status != nil && force == true then
			has_error = true
			$log.info(msg_value + "\tFORCED")
			result = true
		else
			$log.info(msg_value + "\tFAILED")
			$log.info("Finishing Test '#{msg_value}'" + "\tFAILED")
			result = false
		end
	end
	return result, has_error
end



# Non blocking means that have Timeout
def non_blocking_operation ( msg_value = nil, cmd_value= "", timeout_value = 600, force = false)
	$log.info("Running '#{msg_value}'" + "\t...") if !msg_value.nil?
	$pid = nil
	exit_status = nil
	$log.info("#{cmd_value}")
	begin
		Timeout.timeout(timeout_value) do
			stdin, stdout_err, wait_thr = Open3.popen2e(cmd_value)
			$pid = wait_thr.pid
			stdin.close
			while line = stdout_err.gets
				$log.info(line)
			end
			stdout_err.close
			exit_status = wait_thr.value
		end
	rescue Timeout::Error
		$log.error("Process Timeout Error!")
		$log.error("Killing Process...")
		Process.kill 9, $pid
		Process.wait $pid
		$log.error("Process Killed!")
	rescue StandardError => e
		puts "Rescued: #{e.inspect}"
	end

end



# Blocking means that wait until finish
def blocking_operation(msg_value, cmd_value, force = false)
	$log.info("Running '#{msg_value}'"+ "\t...")	if !msg_value.nil?
	exit_status = nil
	$log.info("#{cmd_value}")
	begin
		Open3.popen2e(cmd_value) do |stdin, stdout_err, wait_thr|
			stdin.close
			while line = stdout_err.gets
				$log.info(line)
			end
			stdout_err.close
			exit_status = wait_thr.value
		end
	rescue StandardError => e
		puts "Rescued: #{e.inspect}"
	end

end
