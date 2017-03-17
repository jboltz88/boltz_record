Gem::Specification.new do |s|
  s.name          = 'boltz_record'
  s.version       = '0.0.0'
  s.date          = '2017-03-16'
  s.summary       = 'BoltzRecord ORM'
  s.description   = 'An ActiveRecord-esque ORM adaptor'
  s.authors       = ['Justin Boltz']
  s.email         = 'boltz.justin@gmail.com'
  s.files         = Dir['lib/**/*.rb']
  s.require_paths = ["lib"]
  s.homepage      =
    'http://rubygems.org/gems/boltz_record'
  s.license       = 'MIT'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
end
