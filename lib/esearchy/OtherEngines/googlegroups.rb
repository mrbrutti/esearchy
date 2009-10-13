%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path + lib}

class GoogleGroups
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
    http = Net::HTTP.new("groups.google.com",80)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/groups/search?&safe=off&num=100" + 
                                       "&q=" + CGI.escape(query) + 
                                       "&btnG=Search&start=#{@start}", 
                                       {'User-Agent' => UserAgent::fetch})
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 100
          if @totalhits > @start
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-100} to #{@start}"
            search_emails(response.body)
            sleep(ESearchy::DELAY)
            search(query)
          else
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-100} to #{@start}"
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
  
  def parse(html)
    @totalhits=html.scan(/<\/b> of about <b>(.*)<\/b> for /)[0][0].gsub(",","").to_i if @totalhits == 0
    html.scan(/<div class=g align="left">\
<a href="([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)" target=""/).each do |result|
      case result[0]
      when /.pdf$/i
        @r_pdfs << result[0]
      when /.doc$/i
        @r_docs << result[0]
      when /.docx$|.xlsx$|.pptx$/i
        @r_officexs << result[0]
      when /.txt$|.asn$/i
        @r_txts << result[0]
      else
        @r_urls << result[0]
      end
    end
  end
end