

class RecordTrade

	def initialize( file_name )
		@file = nil
		@file_name_int = file_name

		if !file_name.nil? && file_name != "" then
			directory_name = File.dirname(file_name)
			Dir.mkdir(directory_name) unless File.exists?(directory_name)
			@file = File.open(file_name,  "wb")
			puts "Recordfile: #{file_name}"
		end
	end

	def close()
		puts "Closing recordfile: #{@file_name_int}"
		@file.close if !@file.nil?
		@file = nil
	end

	def record( obj )
		if !obj.nil? then
			obj_mar = Marshal.dump(obj)
			@file.puts( obj_mar.size ) if !@file.nil?
			@file.write( obj_mar ) if !@file.nil?
			@file.flush if !@file.nil?
		end
	end

end


class PlayTrade

	def initialize(file_name)
		@file = nil
		@file_name_int = file_name
		if !file_name.nil? && file_name != "" then
			@file = File.open(file_name,  "rb")
			puts "Recordfile: #{file_name}"
		end
	end

	def close()
		puts "Closing recordfile: #{@file_name_int}"
		@file.close if !@file.nil?
		@file = nil
	end

	def read()
		dmp = nil
		size = @file.readline.to_i  if !@file.nil? && !@file.eof?
		dmp = Marshal.load( @file.read(size) ) if !@file.nil? && !@file.eof?
		return dmp
	end

end
