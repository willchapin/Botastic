require_relative 'bot'
require_relative 'smart_bot'
require_relative 'message'
bot = SmartBot.new

bot.subject = ARGV[0]

puts bot.get_fact


