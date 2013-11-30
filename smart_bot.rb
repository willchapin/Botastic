require 'timeout'
require 'pry'

class SmartBot < Bot

  attr_accessor :subject
  
  def initialize
    @wiki_conn = Faraday.new(:url => 'http://en.wikipedia.org')
    super
  end
  
  def process_message(message)
    puts message
    @subject = get_subjects(message).first
     if @subject
      send_message('private', message['sender_email'], get_fact)
    end
  end

  def get_subjects(message)
    subjects =  message['content'].scan(/tell me about ([^\.]+)/i).flatten
    remove_prefix(subjects, 'the ')
  end

  def remove_prefix(strings, prefix)
    strings.map { |s| s.sub(/#{prefix}/i, "") }
  end
  
  def get_fact
    query_hash = get_query_hash
    change_subject_if_redirect(query_hash)
    page = WikiPage.new(get_content(query_hash))
    set_variants
    page.get_sentence(@variants)
  end

  def get_query_hash
    JSON.parse(get_wiki_page.body)['query']
  end

  def get_content(query_hash)
    query_hash["pages"].map {|key,val| val['extract']}.join
  end
   
  def change_subject_if_redirect(query_hash)
    if query_hash.has_key?('redirects')
      @subject = query_hash['redirects'].first['to']
    end
  end
  
  def get_wiki_page
    @wiki_conn.get '/w/api.php', {
      :action => 'query',
      :prop => 'extracts',
      :format => 'json',
      :explaintext => '',
      :titles => @subject,
      :redirects => ''}
  end
  
  def set_variants
    @variants = @subject.split(" ")
    @variants << acronym if @variants.length > 1
    @variants << @subject
  end

  def acronym
    @variants.map { |str| str[0]}.join("").upcase
  end
  
end
