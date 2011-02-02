
gemspec = eval(File.read(Dir["*.gemspec"].first))

desc 'Run tests'
task :test do
  system 'ruby -I lib -I test test/ts_all.rb'
end

desc "Validate the gemspec"
task :validate do
  gemspec.validate
end

desc 'Build gem locally'
task :build do
  system "gem build #{gemspec.name}.gemspec"
  FileUtils.mkdir_p 'pkg'
  FileUtils.mv "#{gemspec.name}-#{gemspec.version}.gem", "pkg"
end

desc "Install gem locally"
task :install => :build do
  system "gem install pkg/#{gemspec.name}-#{gemspec.version}"
end

desc "Test install gem locally in pkg"
task :test_install => :build do
  FileUtils.mkdir_p 'pkg/gem'
  system "gem install -i pkg/gem pkg/#{gemspec.name}-#{gemspec.version}"
end

desc "Clean automatically generated files"
desc "Clean automatically generated files"
task :clean do
  FileUtils.rm_rf "pkg"
end
