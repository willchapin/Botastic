require 'timeout'

class SmartBot < Bot
  
  def process_message(message)
    subjects = message['content'].scan(/tell me about ([^\.]+)/i)
    puts 'sub'
    puts subjects
    facts = subjects.flatten.map { |subject| get_fact(subject) }
    puts 'fat'
    puts facts
    puts message
    puts 'email'
    puts message['sender_email']
    send_messages('private', message['sender_email'], facts)
  end

  def get_fact(subject)
    @wiki_conn = Faraday.new(:url => 'http://en.wikipedia.org')
    res = get_wiki_page(subject)
    response_hash = JSON.parse(res.body)
    content = response_hash["query"]["pages"].map {|key,val| val['extract']}.join
    paragraphs = content.split("\n")
    get_random_sentence(paragraphs, subject)
  end

  def get_wiki_page(subject)
    @wiki_conn.get '/w/api.php', {
      :action => 'query',
      :prop => 'extracts',
      :format => 'json',
      :explaintext => '',
      :titles => subject,
      :redirects => ''}
  end

  def get_random_sentence(paragraphs, subject)
    paragraph = ""
    sentence = ""
    begin 
      Timeout::timeout(5) {
        until /#{subject}/i.match(sentence) and paragraph.length > 50
          paragraph = paragraphs.sample
          sentence = paragraph.split(". ").sample || ""
        end
      }
    rescue
      sentence = "I don't know anything about that."
    end
    
    sentence
  end  
end
