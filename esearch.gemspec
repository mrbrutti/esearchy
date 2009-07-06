require 'rubygems' 
SPEC = Gem::Specification.new do |s| 
  s.name = "esearchy"
  s.version = "0.0.2"
  s.author = "Matias P. Brutti"
  s.email = "matiasbrutti@gmail.com"
  s.homepage = "http://freedomcoder.com.ar/esearchy"
  s.platform = Gem::Platform::RUBY
  s.summary = "A library to search for emails in search engines"
  s.files = Dir.glob("**/*")
  %w{esearchy}.each do |command_line_utility|
    s.executables << command_line_utility
  end
  s.require_path = "lib"
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README"] 
  s.add_dependency("pdf/reader", ">= 0.7.5")
  s.add_dependency("json", ">= 1.1.6")
  #s.add_dependency("Platform", ">= 0.4.0")
end 
