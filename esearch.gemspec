require 'rubygems'

SPEC = Gem::Specification.new do |s| 
  s.name = "esearchy"
  s.version = "0.0.5"
  s.author = "Matias P. Brutti"
  s.email = "matiasbrutti@gmail.com"
  s.homepage = "http://freedomcoder.com.ar/esearchy"
  s.platform = Gem::Platform::RUBY
  s.summary = "A library to search for emails in search engines"
  s.files = ["esearchy.rb","bin", "bin/esearchy", "data", "data/bing.key", "data/yahoo.key", "lib", "lib/esearchy.rb",
             "lib/esearchy", "lib/esearchy/bing.rb", "lib/esearchy/google.rb", 
             "lib/esearchy/googlegroups.rb", "lib/esearchy/keys.rb", "lib/esearchy/linkedin.rb",
             "lib/esearchy/pdf2txt.rb", "lib/esearchy/pgp.rb", "lib/esearchy/searchy.rb",
             "lib/esearchy/yahoo.rb","lib/esearchy/wcol.rb"]
  %w{esearchy}.each do |command_line_utility|
    s.executables << command_line_utility
  end
  s.require_path = "lib"
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README.rdoc"] 
  s.add_dependency("pdf/reader", ">= 0.7.5")
  s.add_dependency("json", ">= 1.1.6")
  s.add_dependency("rubyzip", ">= 0.9.1")
end 
