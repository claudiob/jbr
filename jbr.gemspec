require_relative 'lib/jbr/version'

Gem::Specification.new do |spec|
  spec.name = 'jbr'
  spec.version = Jbr::VERSION
  spec.authors = [ 'Claudio Baccigalupo' ]
  spec.email = [ 'claudiob@users.noreply.github.com' ]

  spec.summary = 'A Ruby client for the Jobber API.'
  spec.description = 'Jobber API'
  spec.homepage = 'https://github.com/HouseAccountEng/jbr'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/HouseAccountEng/jbr'
  spec.metadata['changelog_uri'] = 'https://github.com/HouseAccountEng/jbr'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile Rakefile .gitignore test/ .github/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ 'lib' ]

  spec.add_dependency 'activesupport' # to tell an empty answer from a missing one
  spec.add_dependency 'company', '~> 2.1' # the vocabulary every record answers in

  spec.add_development_dependency 'minitest' # to run the test suite
  spec.add_development_dependency 'rake' # to run 'bundle exec rake'
  spec.add_development_dependency 'rubocop-rails-omakase' # to run 'bundle exec rubocop'
  spec.add_development_dependency 'simplecov' # to fail the suite below 100% coverage
  spec.add_development_dependency 'webmock' # to answer Jobber without a network
end
