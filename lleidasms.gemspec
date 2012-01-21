$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "lleidasms/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "lleidasms"
  s.version     = Lleidasms::VERSION
  s.authors     = ["Miguel Adolfo Barroso"]
  s.email       = ["mabarroso@mabarroso.com"]
  s.homepage    = "http://www.mabarroso.com/lleidasms"
  s.summary     = "Lleida.net SMS gateway for Ruby."
  s.description = "Receive and send standar and premium SMS/MMS using Lleida.net services."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.1.3"

  s.add_development_dependency "sqlite3"
end
