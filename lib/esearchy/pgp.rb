# http://pgp.mit.edu:11371/pks/lookup?search=.nbg.gr

class PGP
  include Searchy
  
  def initialize(maxhits=nil)
    @emails = []
    @r_urls = Queue.new
    @r_docs = Queue.new
    @r_pdfs = Queue.new
    @r_txts = Queue.new
    @lock = Mutex.new
  end
  
  def search(query)
    @query = query
    http = Net::HTTP.new("pgp.mit.edu",11371)
    begin
      http.start do |http|
        request = Net::HTTP::Get.new( "/pks/lookup?search=#{@query}")
        response = http.request(request)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          puts "Searching #{self.class}"
          search_emails(response.body)
        else
          return response.error!
        end
      end
    rescue Net::HTTPFatalError
      puts "Error: Something went wrong with the HTTP request"
    end
  end
end