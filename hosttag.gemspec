Gem::Specification.new do |s|
  s.name = "hosttag"
  s.version = "0.12"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Gavin Carr"]
  s.email = ["gavin@openfusion.net"]
  s.homepage = "http://github.com/gavincarr/hosttag"
  s.summary = "Hosttag is a client for tagging hostnames into classes using a redis datastore"
  s.description = "Hosttag is a client for tagging hostnames into groups or classes,
storing them in a redis datastore"
  s.rubyforge_project = s.name

  s.required_rubygems_version = ">= 1.3.6"
  
  # If you have runtime dependencies, add them here
  s.add_runtime_dependency "redis", "~> 2.0"
  
  # The list of files to be contained in the gem
  s.files = `git ls-files`.split("\n")
  
  s.require_path = 'lib'
end

