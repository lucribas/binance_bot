# require 'em/pure_ruby'
require 'rubygems'
require 'eventmachine'

class Echo < EventMachine::Connection
  def post_init
    send_data 'Hello'
  end

  def receive_data(data)
    p data
  end
end

EventMachine.run {
  EventMachine::connect '127.0.0.1', 8081, Echo
}
