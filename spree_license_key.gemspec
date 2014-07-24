# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_license_key'
  s.version     = '1.3.0'
  s.summary     = 'Automatic Software License Key Delivery'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'FreeRunning Technologies'
  s.email     = 'contact@freerunningtechnologies.com'
  s.homepage  = 'http://www.freerunningtechnologies.com'

  #s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 1.3.0'
  s.add_dependency 'delayed_job_active_record'

  s.add_development_dependency 'capybara', '1.0.1'
  s.add_development_dependency 'factory_girl', '~> 2.6.4'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.9'
  if ENV['DB'] == 'mysql'
    s.add_development_dependency 'mysql2'
  else
    s.add_development_dependency 'sqlite3'
  end
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rb-inotify'
  s.add_development_dependency 'timecop'
end
