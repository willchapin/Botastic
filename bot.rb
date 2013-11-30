require 'faraday'
require 'json'
require 'open-uri'

class Bot
  
  EMAIL = 'botastic-bot@students.hackerschool.com'
  KEY = '8mnr2NGZbmDNrm7laiDrgMmi51RRW0dW'

  def initialize
    @queue_id = nil
    @last_event_id = nil
    @conn = Faraday.new(:url => 'https://api.zulip.com')
    @conn.basic_auth(EMAIL, KEY)
    register_queue
    process_events!
  end
  
  def register_queue(event_types = '["message"]')
    res = @conn.post '/v1/register', { :event_types => event_types }     
    hash = JSON.parse(res.body)
    @last_event_id = hash['last_event_id']
    @queue_id = hash['queue_id']
  end
  
  def process_events!
    Thread::abort_on_exception = true
    Thread.new do
      while true
        res = get_events
        events = parse_response(res)
        messages = events.select {|event| event["type"] == "message"}
        process_messages(messages)
      end
    end
  end

  def parse_response(res)
    events = JSON.parse(res.body)["events"]
    @last_event_id = events.last["id"]
    events
  end

  def get_events
    params = { :queue_id => @queue_id, :last_event_id => @last_event_id }
    @conn.get('/v1/events', params)
  end
  
  def process_messages(messages)
    messages.each {|message| process_message(message['message']) }
  end

  def process_message(message)
   # puts message
  end

  def send_message(type, to, message, subject = "")
    @conn.post '/v1/messages', { :type => type,
                                 :content => message, 
                                 :to => to,
                                 :subject => subject}
  end
end
