$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rutie'
require 'minitest/autorun'
require 'minitest/reporters'
require 'color_pound_spec_reporter'

Minitest::Reporters.use! [ColorPoundSpecReporter.new]
