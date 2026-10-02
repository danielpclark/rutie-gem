# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'rutie'
  spec.version       = '0.0.4'
  spec.authors       = ['Daniel P. Clark']
  spec.email         = ['6ftdan@gmail.com']
  spec.summary       = 'Rutie helper methods.'
  spec.description   = 'Rutie — The Tie Between Ruby and Rust.  Helper methods gem for Rutie.'
  spec.homepage      = 'https://github.com/danielpclark/rutie'
  spec.license       = 'MIT'

  spec.files         = %w[rutie.gemspec lib/rutie.rb lib/rutie/rake_task.rb LICENSE]

  # Rutie#init loads the extension with Fiddle, a bundled gem rather than a
  # default gem since Ruby 4.0, so Bundler needs it declared.
  spec.add_dependency 'fiddle'
end
