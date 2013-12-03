class WikiPage

  THRESHOLD = 2

  attr_accessor :content, :paragraphs
  
  def initialize(content)
    @content = content
    @paragraphs = get_paragraphs
    filter_paragraphs!(50)
  end

  def get_paragraphs
    @content.split("\n")
  end

  def filter_paragraphs!(len)
    @paragraphs.select! { |p| p.length > len }
  end

  def timed_get_sentence(subject)
    begin
    sentence = Timeout::timeout(5) {  get_final_sentence(subject) }
    rescue
      sentence = "I don't know anything about that."
    end
  end
  
  def get_sentence(variants, original_subject)
    subject = get_final_subject(variants, original_subject)
    timed_get_sentence(subject)
  end
  
  def get_final_sentence(subject)
    loop do
      paragraph = @paragraphs.sample
      sentence = paragraph.split(". ").sample || ""
      return sentence if /#{subject}/i.match(sentence)
    end
  end
  
  def get_frequency(word)
    occurrences = @paragraphs.map {|p| p.scan(/#{word}/).length }
    occurrences.reduce(:+)
  end
 
  def is_disambiguation?(content)
    content[0..100].match(/refer to.*:/)
  end

  def get_final_subject(variants, original_subject)
    freq_hash = make_freq_hash(variants)   
    winning_variant = freq_hash.max_by { |k,v| v }
    subj_freq = original_subject_freq(freq_hash, original_subject)
    begin
      ratio = winning_variant.last/subj_freq.last
    rescue
      ratio  = THRESHOLD + 1
    end
    ratio > THRESHOLD ? winning_variant.first : subj_freq.first
  end


  def make_freq_hash(array)
    array.reduce({}) do |hash, v|
      hash.merge(v => get_frequency(v))
    end
  end

  def original_subject_freq(freq_hash, original_subject)
    freq_hash.select {|k,v| k == original_subject }.to_a.flatten
  end
  
end
