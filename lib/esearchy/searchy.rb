require 'net/http'
local_path = "#{File.dirname(__FILE__)}/"
%w{pdf2txt}.each {|lib| require local_path + lib}

module Searchy
  #Basic method to search for email addresses on strings.
  # in: string to be analyze
  # out: array of found emails 
  def search_emails(string)
    string = string.gsub("<em>","") if self.class == Google #still not sure if this is going to work.
    list = string.scan(/[a-z0-9!#$&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$&'*+=?\^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/)
    print_emails(list)
    @emails.concat(list).uniq!
  end
  
  def search_pdfs(urls)
    urls.uniq.each do |url|
      web = URI.parse(url)
      puts "Searching in PDF: #{url}"
      begin
        http = Net::HTTP.new(web.host,80)
        http.start do |http|
          request = Net::HTTP::Get.new("#{web.path}#{web.query}")
          response = http.request(request)
          case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            name = "/tmp/#{Time.new.to_s}.pdf"
            open(name, "wb") do |file|
              file.write(response.body)
            end
              begin
                receiver = PageTextReceiver.new
                pdf = PDF::Reader.file(name, receiver)
                search_emails(receiver.content.inspect)
              rescue PDF::Reader::UnsupportedFeatureError
                puts "Encrypted PDF: Unable to parse it."
              rescue PDF::Reader::MalformedPDFError
                puts "Malformed PDF: Unable to parse it. "
              end
              `rm "#{name}"`
          else
            return response.error!
          end
        end
      rescue Net::HTTPFatalError
        puts "Error: Something went wrong with the HTTP request"
      rescue Net::HTTPServerException
        puts "Error: Not longer there. 404 Not Found"
      end
    end
  end
  
  def search_docs(urls)
    #TO BE IMPLEMENTED, feeling lazy ... :) 
  end
  
  def search_txts(urls)
    urls.uniq.each do |url|
      web = URI.parse(url)
      puts "Searching in TXT: #{url}"
      begin
        http = Net::HTTP.new(web.host,80)
        http.start do |http|
          request = Net::HTTP::Get.new("#{web.path}#{web.query}")
          response = http.request(request)
          case response
          when Net::HTTPSuccess, Net::HTTPRedirection
            search_emails(response.body)
          else
            return response.error!
          end
        end
      rescue Net::HTTPFatalError
        puts "Error: Something went wrong with the HTTP request"
      rescue Net::HTTPServerException
        puts "Error: Not longer there. 404 Not Found"
      end
    end
  end
  
  # HELPER METHODS --------------------------------------------------------------------------------- 
  
  def print_emails( list )
    list.each do |email|
      unless @emails.include?(email)
        if email.match(/#{@query.gsub("@","").split('.')[0]}/)
          puts "\033[31m" + email + "\033\[0m"
        else
          puts "\033[32m" + email + "\033\[0m"
        end
      end
    end
  end
  def clean( &block )
    @emails.delete_if &block.call
  end
  
  def search_depth
    search_pdfs @r_pdfs
    search_txts @r_txts
    #search_docs @r_docs
  end
end