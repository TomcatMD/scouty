# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestWebcache < Minitest::Test
    include TmpDir

    EXAMPLE_URL = "https://example.com/hello-world"
    EXAMPLE_BODY = "Hello, World!"

    def webcache
      @webcache ||= Webcache.new(dir: tmpdir)
    end

    def test_pulling
      stub_request(:get, EXAMPLE_URL).to_return(body: EXAMPLE_BODY)

      3.times do
        assert_equal EXAMPLE_BODY, webcache.fetch(EXAMPLE_URL)
      end

      assert webcache.stores?(EXAMPLE_URL)
      assert_requested :get, EXAMPLE_URL, times: 1
    end

    def test_storing
      webcache.store(EXAMPLE_URL, EXAMPLE_BODY)

      3.times do
        assert_equal EXAMPLE_BODY, webcache.fetch(EXAMPLE_URL)
      end

      assert webcache.stores?(EXAMPLE_URL)
      assert_not_requested :get, EXAMPLE_URL
    end

    def test_does_not_store
      refute webcache.stores?(EXAMPLE_URL)
    end
  end
end
