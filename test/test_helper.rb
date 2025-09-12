# frozen_string_literal: true

require "simplecov"

SimpleCov.external_at_exit = true
SimpleCov.start do
  add_filter "/test/"
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "scouty"

require "minitest/autorun"
require "minitest/pride"
require "mocha/minitest"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr"
  config.hook_into :webmock
  config.default_cassette_options = {
    match_requests_on: %i[method uri host path headers body]
  }
end

module TmpDir
  def tmpdir
    @tmpdir ||= Dir.mktmpdir.freeze
  end

  def teardown
    super
    FileUtils.remove_entry(@tmpdir) unless @tmpdir.nil?
  end
end
