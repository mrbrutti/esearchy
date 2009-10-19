#
# Big Thanks go to DigiNinja at digininja.org for telling me about this Google Hack.
#
%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path + lib}

class Classmates
  include Searchy
  
  def initialize(maxhits = 0, start = 0)
    @start = start
    @totalhits = maxhits
    @emails = []
    @people = []
    @company_name = nil
    @r_urls = Queue.new
    @r_docs = Queue.new
    @r_pdfs = Queue.new
    @r_txts = Queue.new
    @r_officexs = Queue.new
    @lock = Mutex.new
    @threads = []
  end
  attr_accessor :company_name
  
  def emails
    @emails.uniq!
  end
  
  def emails=(value)
    @emails=value
  end
  
  def people
    @people.uniq!
  end
  
  def people=(value)
    @people=value
  end
  
  def search(query)
    @query = query
    http = Net::HTTP.new("www.google.com",80)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/cse?site%3Awww.classmates.com+%22work+at+" + 
                                      CGI.escape(@company_name) + 
                                      "%22&hl=en&cof=&num=100&filter=0" +   
                                      "&safe=off&start=#{@start}",
                                       {'User-Agent' => UserAgent::fetch})
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 100
          if @totalhits > @start
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-100} to #{@start}"
            parse(response.body)
            search_emails(response.body.gsub(/<em>|<\/em>/,""))
            sleep(ESearchy::DELAY)
            search(query)
          else
            ESearchy::LOG.puts "Searching #{self.class} from #{@start-100} to #{@start}"
            parse(response.body)
            search_emails(response.body.gsub(/<em>|<\/em>/,""))
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
  
  def search_person(name,last)
    email = []
    # Search Yahoo
    y = Yahoo.new(50)
    y.search("first:\"#{name}\" last:\"#{last}\"")
    emails.concat(y.emails).uniq!
    # Search Google
    #g = Google.new(50)
    #g.search("#{name} #{last}")
    #emails.concat(g.emails).uniq!
    return emails
  end
  
  def enquire_person(profile)
    # TO DO: parse profile to obtain more information
  end
  
  def parse(html)
    @totalhits= html.scan(/<\/b> of[ about | ]\
<b>(.*)<\/b> from/)[0][0].gsub(",","").to_i if @totalhits == 0
    html.scan(/<h2 class=r><a href="([0-9A-Za-z:\\\/?&=@+%.;"'()_-]+)" class=l onmousedown="return clk[a-z0-9()'.,]+">([\w\s]*) \|/).each do |profile|
      @domain = @query.match(/@/) ? @query : ("@" + @query)
      name,last = profile[1].split(" ") 
      @people << [name,last]
      @emails << "#{name.split(' ')[0]}.#{last.split(' ')[0]}#{@domain}"
      @emails << "#{name[0,1]}#{last.split(' ')[0]}#{@domain}"
      #@emails.concat(fix(search_person(name,last)))
      @emails.uniq!
      print_emails(@emails)
    end
  end
end