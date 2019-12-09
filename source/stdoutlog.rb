
class StdoutLog
	MAX_COLUMNS	= 100
	MAX_MESSAGE	= 60
	MAX_STATUS	= 10

	def initialize( debug_info, file_name = nil )
		@debug_info = debug_info
		@file = nil
		@file_name_int = file_name
		@stdout_en = true
		@fileout_en = true
		@log_en = @debug_info || @fileout_en

		if !file_name.nil? && file_name != "" then
			directory_name = File.dirname(file_name)
			Dir.mkdir(directory_name) unless File.exists?(directory_name)
			@file = File.new(file_name,  "w")
			puts "Created logfile: #{file_name}"
		end
	end

	def close()
		puts "Closing logfile: #{@file_name_int}"
		@file.close if !@file.nil?
		@file = nil
	end


	def set_debug_info( debug_info )
		@debug_info = debug_info
	end

	def set_fileout_en( fileout_en )
		@fileout_en = fileout_en
		@log_en = @debug_info || @fileout_en
	end

	def set_stdout_en( stdout_en )
		@stdout_en = stdout_en
		@log_en = @debug_info || @fileout_en
	end

	def log_en?()
		return @log_en
	end

	def timestamp()
		time = Time.new
		return time.strftime("%Y-%m-%d %H:%M:%S")
	end

	def none( message )
		if !message.nil? && message != "" then
			message.each_line { |line|
				$stdout.puts line if @stdout_en
				$stdout.flush if @stdout_en
				@file.puts line if (@fileout_en && !@file.nil?)
				@file.flush if (@fileout_en && !@file.nil?)
			}
		end
	end

	def info( message )
		if !message.nil? && message != "" then
			now = timestamp()
			prefix = "|#{now}|INFO:  "
			message.each_line { |line|
				line = prefix + line
				# binding.pry
				$stdout.puts line if @stdout_en
				$stdout.flush if @stdout_en
				@file.puts line if (@fileout_en && !@file.nil?)
				@file.flush if (@fileout_en && !@file.nil?)
			}
		end
	end

	def debug( message )
		if !message.nil? && message != "" then
			if @debug_info == true then
				now = timestamp()
				prefix = "|#{now}|DEBUG: "
				message.each_line { |line|
					line = prefix + line
					$stdout.puts line if @stdout_en
					$stdout.flush if @stdout_en
					@file.puts line if (@fileout_en && !@file.nil?)
					@file.flush if (@fileout_en && !@file.nil?)
				}
			end
		end
	end

	def error( message )
		if !message.nil? && message != "" then
			now = timestamp()
			prefix = "|#{now}|ERROR: "
			message.each_line { |line|
				line = prefix + line
				$stdout.puts line if @stdout_en
				$stdout.flush if @stdout_en
				@file.puts line if (@fileout_en && !@file.nil?)
				@file.flush if (@fileout_en && !@file.nil?)
			}
		end
	end

	def mark( message, status = nil )
		if !message.nil? && message != "" then
			now = timestamp()

			prefix = "|#{now}|MARK:  "

			message = message[0..MAX_MESSAGE-1]
			message = prefix + "## " + message

			bar = prefix
			for i in prefix.size..MAX_COLUMNS-1
				bar = bar + "#"
			end

			line = message
			if !status.nil? && status != "" then
				status = status[0..MAX_STATUS-1]
				status = " [#{status}] "
				for i in message.size..MAX_COLUMNS-status.size-3
					line = line + " "
				end
				line = line + status
			else
				for i in message.size..MAX_COLUMNS-3
					line = line + " "
				end
			end
			message = line + "##"

			$stdout.puts bar
			$stdout.flush if @stdout_en
			@file.puts bar if (@fileout_en && !@file.nil?)
			@file.flush if (@fileout_en && !@file.nil?)

			$stdout.puts message
			$stdout.flush if @stdout_en
			@file.puts message if (@fileout_en && !@file.nil?)
			@file.flush if (@fileout_en && !@file.nil?)

			$stdout.puts bar
			$stdout.flush if @stdout_en
			@file.puts bar if (@fileout_en && !@file.nil?)
			@file.flush if (@fileout_en && !@file.nil?)
		end
	end

	private :timestamp

end
