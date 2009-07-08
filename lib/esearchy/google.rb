%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/"
%w{searchy keys}.each {|lib| require local_path + lib}

class Google
  include Searchy
  
  def initialize(maxhits = nil, start = nil)
    @start = start || 0
    @totalhits = maxhits || 0
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
    http = Net::HTTP.new("www.google.com",80)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/cse?&safe=off&num=100&site=" + 
                                       "&q=" + CGI.escape(query) + 
                                       "&btnG=Search&start=#{@start}")
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 100
          if @totalhits > @start
            puts "Searching in URL: #{self.class} up to point #{@start}"
            search_emails(response.body)
            sleep(4)
            search(query)
          else
            puts "Searching in URL: #{self.class} up to point #{@start}"
            search_emails(response.body)
          end
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      puts "Error: Something went wrong with the HTTP request"
    end
  end
  
  def parse(html)
    @totalhits= html.scan(/<\/b> of about <b>(.*)<\/b> for /)[0][0].gsub(",","").to_i  if @totalhits == 0
    html.scan(/<div class=g><span class="b w xsm">\[([A-Z]+)\]<\/span> <h2 class=r><a href="([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)"|<h2 class=r><a href="([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)"/).each do |result|
      case result[0]
      when /PDF/
        @r_pdfs << result[1]
      when /DOC|XLS|PPT/
        case result[1]
        when /.doc$/i
          @r_docs << result[1]
        when /.docx$|.xlsx$|.pptx$/i
          @r_officexs << result[1]
        end
      when nil
        case result[2]
        when /.pdf$/i
          @r_pdfs << result[2]
        when /.doc$/i
          @r_docs << result[2]
        when /.docx$|.xlsx$|.pptx$/i
          @r_officexs << result[2]
        when /.txt$|.rtf$|ans/i
          @r_txts << result[2]
        else
          @r_urls << result[2]
        end
      else
        puts "I do not parse the #{result[0]} filetype yet:)"
      end
    end
  end
end