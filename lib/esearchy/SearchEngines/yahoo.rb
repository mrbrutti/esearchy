%w{rubygems json cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path  + lib}

class Yahoo
  include Searchy
  
  def initialize(maxhits=0, appid = nil, start=0)
    @appid = appid || Keys::YAHOO_APP_KEY
    @start = start
    @totalhits = maxhits
    @emails = []
    @r_urls = Queue.new
    @r_docs = Queue.new
    @r_pdfs = Queue.new
    @r_officexs = Queue.new
    @r_txts = Queue.new
    @threads = []
    @lock = Mutex.new
  end
  attr_accessor :emails, :appid
  
  def search(query)
    @query = query
    begin
      http = Net::HTTP.new("boss.yahooapis.com",80)
      http.start do |http|
        request = Net::HTTP::Get.new("/ysearch/web/v1/" + CGI.escape(query) + 
                                     "?appid="+ @appid + 
                                     "&format=json&count=50"+ 
                                     "&start=#{@start}", {'User-Agent' => UserAgent::fetch} )
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 50
          if @totalhits > @start
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-50} to #{@start}"
            search_emails(response.body)
            sleep(4)
            search(@query)
          else
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-50} to #{@start}"
            search_emails(response.body)
          end
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      ESearchy::LOG.puts "Error: Something went wrong with the HTTP request"
    end
    @start = 0
  end

  def parse(json)
    doc = JSON.parse(json) 
    @totalhits = doc["ysearchresponse"]["totalhits"].to_i if @totalhits == 0
    doc["ysearchresponse"]["resultset_web"].each do |result|
      case result["url"]
      when /.pdf$/i
        @r_pdfs << result["url"]
      when /.docx$|.xlsx$|.pptx$|.odt$|.odp$|.ods$|.odb$/i
        @r_officexs << result["url"]
      when /.doc$/i
        @r_docs << result["url"]
      when /.txt$|.rtf$|ans$/i
        @r_txts << result["url"]
      else
        @r_urls << result["url"]
      end
    end
  end
end