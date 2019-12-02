
# require 'em/pure_ruby'
require 'rubygems'
require 'eventmachine'

module EchoServer
  def post_init
    puts "-- someone connected to the echo server!"
  end

  def receive_data data
    send_data ">>> you sent: #{data}"
  end
end

EventMachine::run {
  EventMachine::start_server "127.0.0.1", 8081, EchoServer
  puts 'running echo server on 8081'
}
