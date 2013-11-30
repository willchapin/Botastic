require 'timeout'
require 'pry'

class SmartBot < Bot

  THRESHOLD = 2
  
  def process_message(message)
    subjects = get_subjects(message)
    facts = subjects.map { |subject| get_fact(subject) }
    send_messages('private', message['sender_email'], facts)
  end

  def get_subjects(message)
    subjects =  message['content'].scan(/tell me about ([^\.]+)/i).flatten
    remove_prefix(subjects, 'the ')
  end

  def remove_prefix(strings, prefix)
    strings.map { |s| s.sub(/#{prefix}/i, "") }
  end
  
  def get_fact(subject)
    @wiki_conn = Faraday.new(:url => 'http://en.wikipedia.org')
    res = get_wiki_page(subject)
    query_hash = JSON.parse(res.body)['query']
    target = get_target(query_hash, subject)
    content = query_hash["pages"].map {|key,val| val['extract']}.join
    paragraphs = content.split("\n")
    get_random_sentence(paragraphs, target)
  end

  def get_target(query_hash, subject)
    if query_hash.has_key?('redirects')
      query_hash['redirects'].first['to']
    else
      subject  
    end
  end
  
  def get_wiki_page(subject)
    @wiki_conn.get '/w/api.php', {
      :action => 'query',
      :prop => 'extracts',
      :format => 'xml',
      :explaintext => '',
      :titles => subject,
      :redirects => ''}
  end

  def get_random_sentence(paragraphs, subject)
    words = subject.split(" ")
    long_paragraphs = paragraphs.select { |p| p.length > 50 }
    if words.length > 1
      variants = get_variants(words, subject)
      target = get_final_subject(variants, long_paragraphs, subject).keys.first
    else
      target = subject
    end
    paragraph = ""
    sentence = ""
    begin
      Timeout::timeout(5) {
        until /#{target}/i.match(sentence)
          paragraph = long_paragraphs.sample
          sentence = paragraph.split(". ").sample || ""
        end
      }
    rescue
      
      sentence = "I don't know anything about that."
    end
    
    sentence
  end
  
  def get_variants(words, subject)
    words << words.map { |str| str[0]} .join("").upcase if words.length > 1
    words << subject
  end
  
  def get_frequency(word, paragraphs)
    occurrences = paragraphs.map {|p| p.scan(/#{word}/).length }
    occurrences.reduce(:+)
  end
  
  def get_final_subject(variants, paragraphs, subject)
    freq_hash = variants.map {|v| { v => get_frequency(v, paragraphs) } }.reduce {|i,h| i.merge(h)}
    winning_variant = Hash[*freq_hash.max_by {|k,v| v}]
    subj_freq = freq_hash.select {|k,v| k == subject }
    begin
      ratio = winning_variant.values.first/subj_freq.values.first
    rescue
      ratio  = THRESHOLD + 1
    end
    ratio > THRESHOLD ? winning_variant : subj_freq 
  end

  def is_disambiguation?(content)
    content[0..100].match(/refer to.*:/)
  end
  
end
