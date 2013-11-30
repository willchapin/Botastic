require 'timeout'
require 'pry'

class SmartBot < Bot

  THRESHOLD = 2

  def initialize
    @wiki_conn = Faraday.new(:url => 'http://en.wikipedia.org')
    super
  end
  
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
    res = get_wiki_page(subject)
    query_hash = JSON.parse(res.body)['query']
    target = get_redirect(query_hash, subject)
    content = query_hash["pages"].map {|key,val| val['extract']}.join
    page = WikiPage.new(content)
  end

  def get_query
   words = subject.split(" ")
    if words.length > 1
      variants = get_variants(words, subject)
      target = get_final_subject(variants, long_paragraphs, subject).keys.first
    else
      target = subject
    end
  end
  
  def get_redirect(query_hash, subject)
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
      :format => 'json',
      :explaintext => '',
      :titles => subject,
      :redirects => ''}
  end
  
  def get_variants(words, subject)
    words << words.map { |str| str[0]} .join("").upcase if words.length > 1
    words << subject
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

  get_wiki_page = lambda do |subject|
    @wiki_conn.get '/w/api.php', {
      :action => 'query',
      :prop => 'extracts',
      :format => 'json',
      :explaintext => '',
      :titles => subject,
      :redirects => ''}    
  end

  def get_redirect(query_hash, subject)
    if query_hash.has_key?('redirects')
      query_hash['redirects'].first['to']
    else
      subject  
    end
  end
  
end

