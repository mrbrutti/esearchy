%w{rubygems cgi net/http spider}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path + lib}

class Spider
  include Searchy
  
  def initialize(maxhits = nil, start = nil)
    @start = start || 0
    @totalhits = maxhits || 0
    @r_urls = Queue.new
    @r_docs = Queue.new
    @r_pdfs = Queue.new
    @r_txts = Queue.new
    @r_officexs = Queue.new
    @emails = []
    @lock = Mutex.new
    @threads = []
  end
  
  def emails
    @emails.uniq!
  end
  
  def emails=(value)
    @emails=value
  end
  
  def search(query)
    @query = query
    Spidr.site("http://#{@query.gsub("@","")}/") do |spider|      
      spider.every_page do |page|
        ESearchy::LOG.puts page.url
        search_emails(page.body)
        parse(page.body)
      end
  end
  
  def parse(html)
    html.scan(/([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)/).each do |result|
      case result[0]
      when /.pdf$/i
        @r_pdfs << result[0]
      when /.doc$/i
        @r_docs << result[0]
      when /.docx$|.xlsx$|.pptx$|.odt$|.odp$|.ods$|.odb$/i
        @r_officexs << result[0]
      when /.txt$|.asn$/i
        @r_txts << result[0]
      else
        @r_urls << result[0]
      end
    end
  end
end