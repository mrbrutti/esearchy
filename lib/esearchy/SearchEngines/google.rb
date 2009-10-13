%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path + lib}

class Google
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
  
  def emails
    @emails.uniq!
  end
  
  def emails=(value)
    @emails=value
  end
  
  def search(query)
    @query = query
    http = Net::HTTP.new("www.google.com",80)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/cse?&safe=off&num=100&site=" + 
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
            search_emails(response.body.gsub(/<em>|<\/em>/,""))
            sleep(ESearchy::DELAY)
            search(query)
          else
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-100} to #{@start}"
            search_emails(response.body.gsub(/<em>|<\/em>/,""))
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
    @totalhits= html.scan(/<\/b> of about <b>(.*)<\/b> for /)[0][0].gsub(",","").to_i if @totalhits == 0
    html.scan(/<div class=g><span class="b w xsm">\[([A-Z]+)\]<\/span> <h2 class=r><a href="\
([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)"|<h2 class=r><a href="\
([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)"/).each do |result|
      case result[0]
      when /PDF/
        @r_pdfs << result[1]
      when /DOC|XLS|PPT/
        case result[1]
        when /.doc$/i
          @r_docs << result[1]
        when /.docx$|.xlsx$|.pptx$|.odt$|.odp$|.ods$|.odb$/i
          @r_officexs << result[1]
        end
      when nil
        case result[2]
        when /.pdf$/i
          @r_pdfs << result[2]
        when /.doc$/i
          @r_docs << result[2]
        when /.docx$|.xlsx$|.pptx$|.odt$|.odp$|.ods$|.odb$/i
          @r_officexs << result[2]
        when /.txt$|.rtf$|ans$/i
          @r_txts << result[2]
        else
          @r_urls << result[2]
        end
      else
        ESearchy::LOG.puts "I do not parse the #{result[0]} filetype yet:)"
      end
    end
  end
end