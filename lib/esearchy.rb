local_path = "#{File.dirname(__FILE__) + '/esearchy/'}"
%w{google bing yahoo pgp keys linkedin logger}.each { |lib| require local_path + lib } 

class ESearchy
  LIBRARY = 1
  APP = 2
  
  LOG = Logger.new(1, $stdout)
  
  def log_type=(value)
    ESearchy::LOG.level = value
  end
  
  def log_file=(value)
    ESearchy::LOG.file = value
  end
  
  DEFAULT_ENGINES = {"Google" => Google, "Bing" => Bing, "Yahoo" => Yahoo,
                      "PGP" => PGP, "LinkedIn" => LinkedIn }
  
  def initialize(options={}, &block)
    @query = options[:query]
    @depth_search = options[:depth] || true
    @maxhits = options[:maxhits]
    @engines = options[:engines] || DEFAULT_ENGINES
    @engines.each {|n,e| @engines[n] = e.new(@maxhits)}
    @threads = Array.new
    block.call(self) if block_given?
  end
  attr_accessor :engines, :query, :threads, :depth_search
  attr_reader :maxhits
  
  def search(query=nil)
    @engines.each do |n,e|
      LOG.puts "+--- Launching Search for #{n} ---+\n"
      e.search(query || @query)
      e.search_depth if depth_search?
      LOG.puts "+--- Finishing Search for #{n} ---+\n"
    end
  end
  
  def emails
    emails = []
    @engines.each do |n,e|
      emails.concat(@engines[n].emails).uniq!
    end
    emails
  end
  
  def clean(&block)
    emails.each do |e|
      e.delete_if block.call
    end
  end
  
  def maxhits=(value)
    @engines.each do |n,e|
      e.maxhits = value
    end
  end
  
  def yahoo_key=(value)
    @engines['Yahoo'].appid = value
  end
  
  def bing_key=(value)
    @engines['Bing'].appid = value
  end
  
  def linkedin_credentials(user, pass)
    @engines['LinkedIn'].username = user
    @engines['LinkedIn'].password = pass
  end
  alias_method :linkedin_credentials=, :linkedin_credentials
  
  def company_name(company)
    @engines['LinkedIn'].company_name = company
  end
  alias_method :company_name=, :company_name
  
  def search_engine(key, value)
    if [:Google, :Bing, :Yahoo, :PGP, :LinkedIn, :GoogleGroups].include?(key)
      if value == true 
        unless @engines[key.to_s]
          @engines[key.to_s] = instance_eval "#{key}.new(@maxhits)"
        end
      elsif value == false
        @engines.delete(key.to_s)
      end
    else
      raise(ArgumentError, "No plugin with that Key")
    end
  end
  
  %w{Google Bing Yahoo PGP LinkedIn GoogleGroups}.each do |engine|
    class_eval "
      def search_#{engine}=(value)
        search_engine :#{engine}, value
      end"
  end
  
  def save_to_file(file)
    open(file,"a") do |f|
      emails.each { |e| f << e + "\n" }
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
