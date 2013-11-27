require_relative 'bot'
require_relative 'smart_bot'

bot = SmartBot.new

Thread.list.each { |thread| thread.join unless thread == Thread.current }
