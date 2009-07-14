%w{rubygems json cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/"
%w{searchy keys useragent}.each {|lib| require local_path + lib}

class Bing
  include Searchy
  
  def initialize(maxhits = nil, appid=nil, start=nil)
    @appid = appid || Keys::BING_APP_KEY
    @start = start || 0
    @emails = []
    @threads = []
    @totalhits = maxhits || 0
    @r_urls = Queue.new
    @r_docs = Queue.new
    @r_pdfs = Queue.new
    @r_officexs = Queue.new
    @r_txts = Queue.new
    @lock = Mutex.new
  end
  attr_accessor :emails, :appid
  
  def search(query)
    @query = query
    begin
      http = Net::HTTP.new("api.search.live.net",80)
      http.start do |http|
        request = Net::HTTP::Get.new("/json.aspx" + "?Appid="+ @appid + 
                                    "&query=" + CGI.escape(query) + 
                                    "&sources=web&web.count=50&start=#{@start}",
                                    {'Cookie' => UserAgent::fetch})
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 50
          if @totalhits > @start
            ESearchy::LOG.puts "Searching in URL: #{self.class} up to point #{@start}"
            search_emails(response.body)
            sleep(4)
            search(query)
          else
            ESearchy::LOG.puts "Searching in URL: #{self.class} up to point #{@start}"
            search_emails(response.body)
          end
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      ESearchy::LOG.puts "Error: Something went wrong with the HTTP request"
    rescue Errno::ECONNREFUSED
      ESearchy::LOG.puts "Error: < Connection Refused > Hopefuly they have not banned us. :)"
    end
  
  end
  
  def parse(json)
    doc = JSON.parse(json)
    @totalhits = doc["SearchResponse"]["Web"]["Total"].to_i  if @totalhits == 0
    doc["SearchResponse"]["Web"]["Results"].each do |result|
      case result["Url"]
      when /.pdf$/i
        @r_pdfs << result["Url"]
      when /.docx$|.xlsx$|.pptx$|.odt$|.odp$|.ods$|.odb$/i
        @r_officexs << result["Url"]
      when /.doc$/i
        @r_docs << result["Url"]
      when /.txt$|.rtf$|ans$/i
        @r_txts << result["Url"]
      else
        @r_urls << result["Url"]
      end
    end
  end
  
end
