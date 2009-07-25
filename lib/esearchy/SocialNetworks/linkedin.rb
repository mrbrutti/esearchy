%w{rubygems cgi net/http net/https}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path + lib}

class LinkedIn
  include Searchy
  
  def initialize(maxhits = 0)
    @totalhits = maxhits
    @pages = 1
    @emails = []
    @lock = Mutex.new
    @start = 0
    @threads = []
    @lock = Mutex.new
    @username = String.new
    @password = String.new
    @company_name = nil
    @cookie = nil
  end
  attr_accessor :emails, :username, :password, :company_name
  
  def login
    begin
      http = Net::HTTP.new("www.linkedin.com",443)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.start do |http|
        request = Net::HTTP::Post.new("/secure/login",
                                      {'Content-Type' => "application/x-www-form-urlencoded"})
        request.body = "session_key=#{@username}" +
                       "&session_password=#{@password}" +
                       "&session_login=Sign+In&session_login=&session_rikey="
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          return response['Set-Cookie']
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      ESearchy::LOG.puts "Error: Something went wrong with the HTTP request"
    end
  end
  
  def search(query)
    @query = query
    begin 
        @cookie = login
    rescue
      ESearchy::LOG.puts "Unable to parse LinkedIn. Something went Wrong with the Credentials"
      return nil
    end
    begin
      http = Net::HTTP.new("www.linkedin.com",80)
      http.start do |http|
        #request = Net::HTTP::Get.new("/search?search=&viewCriteria=1&currentCompany=co" + 
        #          "&searchLocationType=Y&newnessType=Y" +
        #          "&proposalType=Y&pplSearchOrigin=ADVS&company=#{CGI.escape(@company_name)}" +
        #          "&sortCriteria=Relevance&page_num=#{@pages}", {'Cookie' => @cookie} )
        
        headers = {'Cookie' => @cookie, 'User-Agent' => UserAgent::fetch}
        request = Net::HTTP::Get.new("/search?search=&company=" + 
                                     CGI.escape(@company_name) +
                                     "&currentCompany=currentCompany" + 
                                     "&trk=coprofile_in_network_see_more" + 
                                     "&page_num=" + @pages.to_s, headers)
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 10
          if @totalhits > @start
            @pages = @pages + 1
            ESearchy::LOG.puts "Searching in: #{self.class} up to point #{@start}"
            search_people(response.body)
            create_emails
            sleep(4)
            search(@query)
          else
            ESearchy::LOG.puts "Searching in: #{self.class} up to point #{@start}"
            search_people(response.body)
            create_emails
          end
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      ESearchy::LOG.puts "Error: Something went wrong with the HTTP request"
    end
  end

  def parse(string)
    @totalhits = string.scan(/<p class="summary>"<strong>(.*)<\/strong>/) if @totalhits == 0
  end
  
  def search_people(string)
    @people = string.scan(/title="View profile">[\n\s]+<span class="given-name">(.*)<\/span>\
[\n\s]+<span class="family-name">(.*)<\/span>/)
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
    
  def create_emails
    @domain = @query.match(/@/) ? @query : ("@" + @query)
    @people.each do |person|
      name,last = person 
      @emails << "#{name.split(' ')[0]}.#{last.split(' ')[0]}#{@domain}"
      @emails << "#{name[0,1]}#{last.split(' ')[0]}#{@domain}"
      #@emails.concat(fix(search_person(name,last)))
      @emails.uniq!
    end 
    print_emails(@emails)
  end
end
