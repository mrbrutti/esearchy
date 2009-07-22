%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/"
%w{searchy keys useragent}.each {|lib| require local_path + lib}

class Altavista
  include Searchy
  
  def initialize(maxhits = 0, start = 0)
    @start = start
    @totalhits = maxhits
    @emails = []
    @r_urls = Queue.new
    @r_docs = Queue.new
    @r_pdfs = Queue.new
    @r_txts = Queue.new
    @r_officexs = Queue.new
    @lock = Mutex.new
    @threads = []
  end
  attr_accessor :emails
  
  def search(query)
    @query = query
    http = Net::HTTP.new("www.altavista.com",80)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/web/results?itag=ody&kgs=0&kls=0&nbq=50" + 
                                       "&q=" + CGI.escape(query) + 
                                       "&stq=#{@start}", 
                                       {'Cookie' => UserAgent::fetch})
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 100
          if @totalhits > @start
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-50} to #{@start}"
            search_emails(response.body.gsub(/<b>|<\/b>/,""))
            sleep(4)
            search(query)
          else
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-50} to #{@start}"
            search_emails(response.body.gsub(/<b>|<\/b>/,""))
          end
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      ESearchy::LOG.puts "Error: Something went wrong with the HTTP request"
    end
  end
  
  def parse(html)
    @totalhits= html.scan(/AltaVista found (.*) results<\/A>/)[0][0].gsub(',','').to_i if @totalhits == 0
    html.scan(/<a class='res' href='([a-zA-Z0-9:\/\/.&?%=\-_+]*)'>/).each do |result|
      case result[0]
      when /.pdf$/i
        @r_pdfs << CGI.unescape(result[0])
      when /.docx$|.xlsx$|.pptx$|.odt$|.odp$|.ods$|.odb$/i
        @r_officexs << CGI.unescape(result[0])
      when /.doc$/i
        @r_docs << CGI.unescape(result[0])
      when /.txt$|.rtf$|ans$/i
        @r_txts << CGI.unescape(result[0])
      else
        @r_urls << CGI.unescape(result[0])
      end
    end
  end
end