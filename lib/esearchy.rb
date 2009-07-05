local_path = "#{File.dirname(__FILE__) + '/esearchy/'}"
%w{google bing yahoo}.each { |lib| require local_path + lib } 

class ESearchy
  def initialize(options={}, &block)
    @query = options[:query]
    @depth_search = options[:depth] || true
    @maxhits = options[:maxhits]
    @engines = options[:engines] || {"Google" => Google, 
                                     "Bing" => Bing, 
                                     "Yahoo" => Yahoo,
                                     "Pgpg" => Pgp }
    @engines.each do |n,e| 
      @engines[n] = e.new(@maxhits)
    end
    @emails = Array.new
    @threads = Array.new
    block.call(self) if block_given?
  end
  attr_accessor :engines, :query, :threads, :maxhits, :depth_search
  
  def search(query=nil)
    @engines.each do |n,e|
      puts "+--- Launching Search for #{n} ---+\n"
      e.search(query || @query)
      e.search_depth if depth_search?
      puts "+--- Finishing Search for #{n} ---+\n"
    end
  end
  
  def emails
    @engines.each do |n,e|
      @emails.concat(e.emails).uniq!
    end
    @emails
  end
  
  def clean(&block)
    emails.each do |e|
      e.delete_if block.call
    end
  end
  
  def save_to_file(file)
    open(file,"w") do |f|
      emails.each { |e| f << e }
    end
  end
  
  def filter(regex)
    emails.each.select { |email| email =~ regex }
  end

  def self.create(query=nil, &block)
    self.new :query => query do |search|
      block.call(search) if block_given?
    end
  end
  
  private
  
  def depth_search?
    @depth_search
  end
  
end
