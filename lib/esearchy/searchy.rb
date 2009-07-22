require 'digest/sha2'
require 'net/http'
require 'zip/zip'
require 'zip/zipfilesystem'
local_path = "#{File.dirname(__FILE__)}/"
require local_path + 'pdf2txt'
if RUBY_PLATFORM =~ /mingw|mswin/
 require 'win32ole'
 require local_path + 'wcol'
end

module Searchy
  case RUBY_PLATFORM 
  when /mingw|mswin/
    TEMP = "C:\\WINDOWS\\Temp\\"
  else
    TEMP = "/tmp/"
  end    
  
  def search_emails(string)
    list = string.scan(/[a-z0-9!#$&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$&'*+=?^_`{|}~-]+)*_at_\
(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z](?:[a-z-]*[a-z])?|\
[a-z0-9!#$&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$&'*+=?^_`{|}~-]+)*\sat\s(?:[a-z0-9](?:[a-z0-9-]\
*[a-z0-9])?\.)+[a-z](?:[a-z-]*[a-z])?|[a-z0-9!#$&'*+=?^_`{|}~-]+\
(?:\.[a-z0-9!#$&'*+=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z](?:[a-z-]*[a-z])?|\
[a-z0-9!#$&'*+=?^_`{|}~-]+(?:\.[a-z0-9!#$&'*+=?^_`{|}~-]+)*\s@\s(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+\
[a-z](?:[a-z-]*[a-z])?|[a-z0-9!#$&'*+=?^_`{|}~-]+(?:\sdot\s[a-z0-9!#$&'*+=?^_`\
{|}~-]+)*\sat\s(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\sdot\s)+[a-z](?:[a-z-]*[a-z])??/)
    @lock.synchronize do
      print_emails(list)
      @emails.concat(fix(list)).uniq!
    end
  end
  
  def search_pdfs(urls)
    while urls.size >= 1
      @threads << Thread.new do
        web = URI.parse(urls.pop)
        ESearchy::LOG.puts "Searching in PDF: #{web.to_s}\n"
        begin
          http = Net::HTTP.new(web.host,80)
          http.start do |http|
            request = Net::HTTP::Get.new("#{web.path}#{web.query}")
            response = http.request(request)
            case response
            when Net::HTTPSuccess, Net::HTTPRedirection
              name = Searchy::TEMP + "#{hash_url(web.to_s)}.pdf"
              open(name, "wb") do |file|
                file.write(response.body)
              end
              begin
                receiver = PageTextReceiver.new
                pdf = PDF::Reader.file(name, receiver)
                search_emails(receiver.content.inspect)
              rescue PDF::Reader::UnsupportedFeatureError
                ESearchy::LOG.puts "Encrypted PDF: Unable to parse it.\n"
              rescue PDF::Reader::MalformedPDFError
                ESearchy::LOG.puts "Malformed PDF: Unable to parse it.\n"
              end
              `rm "#{name}"`
            else
              return response.error!
            end
          end
        rescue Net::HTTPFatalError
          ESearchy::LOG.puts "Error: Something went wrong with the HTTP request.\n"
        rescue Net::HTTPServerException
          ESearchy::LOG.puts "Error: Not longer there. 404 Not Found.\n"
        rescue
          ESearchy::LOG.puts "Error: < .. SocketError .. >\n"
        end
      end
    end
    @threads.each {|t| t.join } if @threads != nil
  end
  
  def search_docs(urls)
    while urls.size >= 1
       @threads << Thread.new do
         web = URI.parse(urls.pop)
         ESearchy::LOG.puts "Searching in DOC: #{web.to_s}\n"
         begin
           http = Net::HTTP.new(web.host,80)
           http.start do |http|
             request = Net::HTTP::Get.new("#{web.path}#{web.query}")
             response = http.request(request)
             case response
             when Net::HTTPSuccess, Net::HTTPRedirection
               name = Searchy::TEMP + "#{hash_url(web.to_s)}.doc"
               open(name, "wb") do |file|
                 file.write(response.body)
               end
               if RUBY_PLATFORM =~ /mingw|mswin/
                 begin
                   word = WIN32OLE.new('word.application')
                   word.documents.open(name)
                   word.selection.wholestory
                   search_emails(word.selection.text.chomp)
                   word.activedocument.close( false )
                   word.quit
                 rescue
                   if File.exists?("C:\\antiword\\antiword.exe")
                     search_emails(`C:\\antiword\\antiword.exe "#{name}" -f -s`)
                   else
                      # This G h e t t o but, for now it works on emails 
                      # that do not contain Capital letters:)
                      ESearchy::LOG.puts "M$ Word|Antiword are not installed. Using the Ghetto way."
                      search_emails( File.open(name).readlines[0..19].to_s )
                   end
                 end
                elsif RUBY_PLATFORM =~ /linux|darwin/
                  begin
                    if File.exists?("/usr/bin/antiword") or 
                       File.exists?("/usr/local/bin/antiword") or 
                       File.exists?("/opt/local/bin/antiword")
                      search_emails(`antiword "#{name}" -f -s`)
                    else
                      # This G h e t t o but, for now it works on emails 
                      # that do not contain Capital letters:)
                      ESearchy::LOG.puts "Antiword is not installed. Using the Ghetto way."
                      search_emails( File.open(name).readlines[0..19].to_s )
                    end
                  rescue
                    ESearchy::LOG.puts "Something went wrong parsing the .doc\n"
                  end
                else
                  ESearchy::LOG.puts "This platform is not currently supported."
                end
               `rm "#{name}"`
             else
               return response.error!
             end
           end
         rescue Net::HTTPFatalError
           ESearchy::LOG.puts "Error: Something went wrong with the HTTP request.\n"
         rescue Net::HTTPServerException
           ESearchy::LOG.puts "Error: Not longer there. 404 Not Found.\n"
         rescue
           ESearchy::LOG.puts "Error: < .. SocketError .. >\n"
         end
       end
     end
     @threads.each {|t| t.join } if @threads != nil
  end
  
  def search_office_xml(urls)
    while urls.size >= 1
      @threads << Thread.new do
        web = URI.parse(urls.pop)
        #format = web.scan(/docx|xlsx|pptx/i)[0]
        format = web.scan(/docx|xlsx|pptx|odt|odp|ods|odb/i)[0]
        ESearchy::LOG.puts "Searching in #{format.upcase}: #{web.to_s}\n"
        begin
          http = Net::HTTP.new(web.host,80)
          http.start do |http|
            request = Net::HTTP::Get.new("#{web.path}#{web.query}")
            response = http.request(request)
            case response
            when Net::HTTPSuccess, Net::HTTPRedirection
              name = Searchy::TEMP + "#{hash_url(web.to_s)}." + format
              open(name, "wb") do |file|
                file.write(response.body)
              end
              begin
                Zip::ZipFile.open(name) do |zip|
                  text = z.entries.each { |e| zip.file.read(e.name) if e.name =~ /.xml$/}
                  search_emails(text)
                end
              rescue
                ESearchy::LOG.puts "Something went wrong parsing the .#{format.downcase}\n"
              end
              `rm "#{name}"`
            else
              return response.error!
            end
          end
        rescue Net::HTTPFatalError
          ESearchy::LOG.puts "Error: Something went wrong with the HTTP request.\n"
        rescue Net::HTTPServerException
          ESearchy::LOG.puts "Error: Not longer there. 404 Not Found.\n"
        rescue
          ESearchy::LOG.puts "Error: < .. SocketError .. >\n"
        end
      end
    end
    @threads.each {|t| t.join } if @threads != nil
  end
   
  def search_txts(urls)
    while urls.size >= 1
      @threads << Thread.new do 
        web = URI.parse(urls.pop)
        ESearchy::LOG.puts "Searching in #{web.to_s.scan(/txt|rtf|ans/i)[0].upcase}: #{web.to_s}\n"
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
          ESearchy::LOG.puts "Error: Something went wrong with the HTTP request\n"
        rescue Net::HTTPServerException
          ESearchy::LOG.puts "Error: Not longer there. 404 Not Found.\n"
        rescue
          ESearchy::LOG.puts "Error: < .... >"
        end
      end
    end
    @threads.each {|t| t.join } if @threads != nil
  end
  
  # HELPER METHODS --------------------------------------------------------------------------------- 
  
  def print_emails(list)
    list.each do |email|
      unless @emails.include?(email)
        unless RUBY_PLATFORM =~ /mingw|mswin/
          if email.match(/#{@query.gsub("@","").split('.')[0]}/)
            ESearchy::LOG.puts "\033[31m" + email + "\033\[0m"
          else
            ESearchy::LOG.puts "\033[32m" + email + "\033\[0m"
          end
        else
          if email.match(/#{@query.gsub("@","").split('.')[0]}/)
            Wcol::color(12)
            ESearchy::LOG.puts email
            Wcol::color(7)
          else
            Wcol::color(2)
            ESearchy::LOG.puts email
            Wcol::color(7)
          end
        end
      end
    end
  end
  
  def hash_url(url)
    Digest::SHA2.hexdigest("#{Time.now.to_f}--#{url}")
  end
  
  def fix(list)
    list.each do |e|
      e.gsub!(" at ","@")
      e.gsub!("_at_","@")
      e.gsub!(" dot ",".")
    end
  end
  
  def clean( &block )
    @emails.delete_if &block.call
  end
  
  def maxhits=( value )
    @totalhits = value
  end
    
  def search_depth
    search_pdfs @r_pdfs if @r_pdfs
    search_txts @r_txts if @r_txts
    search_office_xml @r_officexs if @r_officexs
    if RUBY_PLATFORM =~ /mingw|mswin/
      search_docs @r_docs if @r_docs
    end
  end
end