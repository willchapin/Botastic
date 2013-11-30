class WikiPage


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
      Timeout::timeout(5) { sentence =  get_sentence(subject) }
    rescue
      sentence = "I don't know anything about that."
    end
    sentence
  end

  def get_sentence(subject)
    until /#{subject}/i.match(sentence)
      paragraph = @paragraphs.sample
      sentence = paragraph.split(". ").sample || ""
    end
    sentence
  end
  

    words = subject.split(" ")
    long_paragraphs = filter_paragraphs(50)
    if words.length > 1
      variants = get_variants(words, subject)
      target = get_final_subject(variants, long_paragraphs, subject).keys.first
    else
      target = subject
    end
    


  

  
  def get_frequency(word, paragraphs)
    occurrences = paragraphs.map {|p| p.scan(/#{word}/).length }
    occurrences.reduce(:+)
  end
 
  def is_disambiguation?(content)
    content[0..100].match(/refer to.*:/)
  end

end
