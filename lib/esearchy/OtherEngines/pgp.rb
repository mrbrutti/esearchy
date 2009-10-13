%w{cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/../"
%w{searchy useragent}.each {|lib| require local_path + lib}

class PGP
  include Searchy
  
  def initialize(maxhits=0)
    @totalhits = maxhits
    @emails = []
    @lock = Mutex.new
  end
  
  def emails
    @emails.uniq!
  end
  
  def emails=(value)
    @emails=value
  end
  
  def search(query)
    @query = query
    http = Net::HTTP.new("pgp.mit.edu",11371)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/pks/lookup?search=#{@query}",
                                      {'User-Agent' => UserAgent::fetch})
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          ESearchy::LOG.puts "Searching #{self.class}"
          search_emails(response.body)
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      ESearchy::LOG.puts "Error: Something went wrong with the HTTP request"
    end
  end
end