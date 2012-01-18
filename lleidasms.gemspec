lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'lleidasms'

Gem::Specification.new do |s|
  s.name = "lleidasms"
  s.version = Lleidasms::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Miguel Adolfo Barroso"]
  s.email = ["mabarroso@mabarroso.com"]
  s.homepage = "http://www.mabarroso.com/lleidasms"
  s.summary = %q{Lleida.net SMS gateway for Ruby.}
  s.description = %q{Receive and send standar and premium SMS/MMS using Lleida.net services.}

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
end