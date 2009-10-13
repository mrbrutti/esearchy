SPEC = Gem::Specification.new do |s| 
  s.name = "esearchy"
  s.version = "0.1.2.3"
  s.author = "Matias P. Brutti"
  s.email = "matiasbrutti@gmail.com"
  s.homepage = "http://freedomcoder.com.ar/esearchy"
  s.platform = Gem::Platform::RUBY
  s.summary = "A library to search for emails in search engines"
  s.files = ["bin", "bin/esearchy", 
             "data", "data/bing.key", "data/yahoo.key", "lib", 
             "esearchy.rb",
             "lib/esearchy",
             "lib/esearchy.rb",
             "lib/esearchy/bugmenot.rb",
             "lib/esearchy/keys.rb", 
             "lib/esearchy/logger.rb",
             "lib/esearchy/OtherEngines", 
             "lib/esearchy/OtherEngines/pgp.rb",
             "lib/esearchy/OtherEngines/googlegroups.rb", 
             "lib/esearchy/OtherEngines/usenet.rb",
             "lib/esearchy/pdf2txt.rb",
             "lib/esearchy/SearchEngines/",
             "lib/esearchy/SearchEngines/bing.rb",
             "lib/esearchy/SearchEngines/google.rb",
             "lib/esearchy/SearchEngines/yahoo.rb", 
             "lib/esearchy/SearchEngines/altavista.rb",
             "lib/esearchy/searchy.rb",
             "lib/esearchy/SocialNetworks/",
             "lib/esearchy/SocialNetworks/googleprofiles.rb",
             "lib/esearchy/SocialNetworks/linkedin.rb",
             "lib/esearchy/SocialNetworks/naymz.rb",
             "lib/esearchy/wcol.rb",
             "lib/esearchy/useragent.rb"]
  %w{esearchy}.each do |command_line_utility|
    s.executables << command_line_utility
  end
  s.require_path = "lib"
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README.rdoc"] 
  s.add_dependency("pdf-reader", ">= 0.7.5")
  s.add_dependency("json", ">= 1.1.6")
  s.add_dependency("FreedomCoder-rubyzip", ">= 0.9.3") # This is for Ruby-1.9 compatibility
end 
