%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/"
%w{yahoo google}.each {|lib| require local_path + lib}

# http:///
class Linkedin
  include Searchy
  
  def initialize(maxhits=nil, start=nil)
    @totalhits = maxhits || 0
    @pages = 1
    @emails = []
    @lock = Mutex.new
    @start = start || 0
    @threads = []
    @lock = Mutex.new
  end
  attr_accessor :emails, :appid
  
  def search(query)
    @query = query
    begin
      http = Net::HTTP.new("www.linkedin.com",80)
      http.start do |http|
        request = Net::HTTP::Get.new("search?search=&company=" + @query + 
                                     "&currentCompany=currentCompany" + 
                                     "&trk=coprofile_in_network_see_more" + 
                                     "&page_num=" + @pages)
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 10
          if @totalhits > @start
            @pages = @pages + 1
            puts "Searching in: #{self.class} up to point #{@start}"
            create_emails(response.body)
            sleep(4)
            search(@query)
          else
            puts "Searching in: #{self.class} up to point #{@start}"
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

  def parse(string)
    @totalhits = string.scan(/<p class="summary>"<strong>(\w)<\/strong>/) if @totalhits == 0
  end
  
  def search_people(string)
    @people = string.scan(/<spam class="given-name">(*.)<\/spam><spam class="family-name">(*.)<\/spam>)/)
  end
  def search_person(name,last)
    emails = Yahoo.new(50).search("first:\"#{name}\" last:\"#{last}\"").emails
    emails.concat(Google.new(50).search("#{name} #{last}").emails).uniq!
  end
    
  def create_emails
    @domain = + @query.match(/@/) ? @query : ("@" + @query)
    @people.each do |person|
      name = person[0]
      last = person[1] 
      @emails << name + last + @domain
      @emails << name[0] + last + @domain
      @emails.concat(search_person(name,last))
    end 
    print_emails(@emails)
  end
end
