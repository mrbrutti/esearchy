require 'resolv'
local_path = "#{File.dirname(__FILE__) + '/esearchy/'}"
%w{google googlegroups bing yahoo pgp keys altavista usenet
   linkedin logger bugmenot}.each { |lib| require local_path + lib } 

class ESearchy
  
  #Constants 
  LIBRARY = 1
  APP = 2
  LOG = Logger.new(1, $stdout)
  BUGMENOT = BMN::fetch_user("linkedin.com")
  DEFAULT_ENGINES = [:Google, :Bing, :Yahoo, :PGP, :LinkedIn, :GoogleGroups, :Altavista, :Usenet]
  #End Constants
  
  def log_type=(value)
    ESearchy::LOG.level = value
  end
  
  def log_file=(value)
    ESearchy::LOG.file = value
  end
  
  def initialize(options={}, &block)
    @query = options[:query]
    @depth_search = options[:depth] || true
    @maxhits = options[:maxhits] || 0
    @engines = options[:engines] ? eng(options[:engines]) : 
                                   { :Google => Google, 
                                     :Bing => Bing, 
                                     :Yahoo => Yahoo,
                                     :PGP => PGP, 
                                     :LinkedIn => LinkedIn,
                                     :GoogleGroups => GoogleGroups,
                                     :Altavista => Altavista,
                                     :Usenet => Usenet }
    @engines.each {|n,e| @engines[n] = e.new(@maxhits)}
    @threads = Array.new
    block.call(self) if block_given?
  end
  
  #Attributes
  attr_accessor :engines, :query, :threads, :depth_search
  attr_reader :maxhits

  def self.create(query=nil, &block)
    self.new :query => query do |search|
      block.call(search) if block_given?
    end
  end
  
  def search(query=nil)
    @engines.each do |n,e|
      LOG.puts "+--- Launching Search for #{n} ---+\n"
      e.search(query || @query)
      e.search_depth if depth_search?
      LOG.puts "+--- Finishing Search for #{n} ---+\n"
    end
  end
  # retrieve emails
  def emails
    emails = []
    @engines.each do |n,e|
      emails.concat(@engines[n].emails).uniq!
    end
    emails
  end
  ## Filter methods ##
  def clean(&block)
    emails.each do |e|
      e.delete_if block.call
    end
  end
  
  def filter(regex)
    emails.each.select { |email| email =~ regex }
  end
  
  def filter_by_score(score)
    emails.each.select { |email| score >= calculate_score(emails) }
  end
    
  ## Option methods ##
  def maxhits=(value)
    @engines.each do |n,e|
      e.maxhits = value
    end
  end
  
  def yahoo_key=(value)
    @engines[:Yahoo].appid = value
  end
  
  def bing_key=(value)
    @engines[:Bing].appid = value
  end
  
  def linkedin_credentials
    return @engines[:LinkedIn].username, @engines[:LinkedIn].password
  end
  
  def linkedin_credentials=(*args)
    if args.size == 2
      @engines[:LinkedIn].username = args[0]
      @engines[:LinkedIn].password = args[1]
      return true
    elsif args.size == 1
      @engines[:LinkedIn].username = args[0][0]
      @engines[:LinkedIn].password = args[0][1]
      return true
    end
    false
  end
  
  def company_name
    @engines[:LinkedIn].company_name
  end
  
  def company_name=(company)
    @engines[:LinkedIn].company_name = company
  end
  
  def search_engine(key, value)
    if [:Google, :Bing, :Yahoo, :PGP, :LinkedIn, :GoogleGroups, :AltaVisa, :Usenet].include?(key)
      if value == true 
        unless @engines[key]
          @engines[key] = instance_eval "#{key}.new(@maxhits)"
        end
      elsif value == false
        @engines.delete(key)
      end
    else
      raise(ArgumentError, "No plugin with that Key")
    end
  end
  
  %w{Google Bing Yahoo PGP LinkedIn GoogleGroups Altavista Usenet}.each do |engine|
    class_eval "
      def search_#{engine}=(value)
        search_engine :#{engine}, value
      end"
  end
  ## Saving methods
  def save_to_file(file, list=nil)
    open(file,"a") do |f|
      list ? list.each { |e| f << e + "\n" } : emails.each { |e| f << e + "\n" }
    end
  end
  
  def save_to_sqlite(file)
    # TODO save to sqlite3
    # table esearchy with fields (id, Domain, email, score)
  end

  ## checking methods ##
  
  def verify_email!(arg = emails)
    # TODO
    # Connect to mail server if possible verify else 
    # return 0 for false  2 for true or 1 for error.
    # VRFY & EXPN & 'RCPT TO:
    return false
  end
  
  def verify_domain!(e)
    Resolv::DNS.open.getresources(e.split('@')[-1],Resolv::DNS::Resource::IN::MX) > 0 ? true : false
  end
  
  private
  
  def eng(arr)
    hsh = {}; arr.each {|e| hsh[e] = instance_eval "#{e}"}; hsh
  end
  
  def calculate_score(email)
    score = 0.0
    score = score + 0.2 if email =~ /#{@query}/
    score = score + 0.3 if verify_domain!(email)  
    score = 1.0 if verify_email!(email)
  end
  
  def depth_search?
    @depth_search
  end
  
end
