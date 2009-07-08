%w{rubygems cgi net/http}.each { |lib| require lib }
local_path = "#{File.dirname(__FILE__)}/"
%w{searchy keys}.each {|lib| require local_path + lib}

class Linkedin
  include Searchy
  
  def initialize( )

  end
  attr_accessor :emails, :appid
  
  def search(query)
    @query = query
    begin
      http = Net::HTTP.new("",80)
      http.start do |http|
        request = Net::HTTP::Get.new()
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          parse(response.body)
          @start = @start + 50
          if @totalhits > @start
            puts "Searching in URL: #{self.class} up to point #{@start}"
            search_emails(response.body)
            sleep(4)
            search(@query)
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

  def parse(json)
  end
end
