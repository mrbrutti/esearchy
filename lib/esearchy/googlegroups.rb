%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/"
%w{searchy keys}.each {|lib| require local_path + lib}

class GoogleGroups
  include Searchy
  
  def initialize(maxhits = nil, start = nil)
    @start = start || 0
    @totalhits = maxhits || 0
    @emails = []
    @r_urls = []
    @r_docs = []
    @r_pdfs = []
    @r_txts = []
  end
  
  attr_accessor :emails
  
  def search(query)
    @query = query
    http = Net::HTTP.new("groups.google.com",80)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/groups/search?&safe=off&num=100" + 
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
    html.scan(/<div class=g align="left"><a href="([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)" target=""/).each do |result|
      case result[0]
        when /.pdf$/
          @r_pdfs << result[0]
        when /.doc$/
          @r_docs << result[0]
        when /.txt$/
          @r_txts << result[0]
        else
          @r_urls << result[0]
        end
      else
        puts "I do not parse the #{result[0]} filetype yet:)"
      end
    end
  end
end