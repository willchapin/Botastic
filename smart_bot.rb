class SmartBot < Bot
  
  def process_message(message)
    sentences = message['content'].split(". ")
    sentences.each do |sentence|
      subjects =  sentence.scan(/tell me about (.+)/i)
      subjects.flatten.each { |subject| get_fact(subject) }
    end
  end

  def get_fact(subject)
    @wiki_conn = Faraday.new(:url => 'http://en.wikipedia.org')
    res = get_wiki_page(subject)
    response_hash = JSON.parse(res.body)
    content = response_hash["query"]["pages"].map {|key,val| val['extract']}.join
    paragraphs = content.split("\n")
    sentence = find_sentence(paragraphs, subject)
    send_message('private', 'wrchapin@gmail.com', sentence)
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

  def find_sentence(paragraphs, subject)
    paragraph = ""
    sentence = ""
    until /#{subject}/i.match(sentence) and paragraph.length > 50
      paragraph = paragraphs.sample
      sentence = paragraph.split(". ").sample || ""
    end
    sentence
  end  
end
