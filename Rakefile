
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name     'lleidasms'
  authors  'Miguel Adolfo Barroso'
  email    'mabarroso@mabarroso.com'
  url      'http://www.mabarroso.com/lleidasms'
}

