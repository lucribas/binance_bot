

require 'pry'
require 'telegram/bot'
require_relative 'secret_keys'

Telegram::Bot::Client.run(telegram_token) do |bot|
	bot.listen do |message|
		puts "From: #{message.chat.id}:#{message.chat.first_name} = #{message.text}"
		case message.text
			when '/start'
				bot.api.send_message(chat_id: message.chat.id, text: "I am the Luciano bot, My commands are /g and /map")
			when '/g'
				bot.api.send_message(chat_id: message.chat.id, text: "Welcome to http://www.google.com")
			when '/map'
				bot.api.send_location(chat_id: message.chat.id, latitude: -37.807416, longitude: 144.985339)
		end
	end
end
