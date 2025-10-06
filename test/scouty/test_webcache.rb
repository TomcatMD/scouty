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

    def test_fetching
      webcache
        .fetcher
        .expects(:fetch)
        .with(EXAMPLE_URL)
        .returns(EXAMPLE_BODY)
        .once

      3.times do
        assert_equal EXAMPLE_BODY, webcache.fetch(EXAMPLE_URL)
      end

      assert webcache.stores?(EXAMPLE_URL)
    end

    def test_storing
      webcache
        .fetcher
        .expects(:fetch)
        .never

      webcache.store(EXAMPLE_URL, EXAMPLE_BODY)

      3.times do
        assert_equal EXAMPLE_BODY, webcache.fetch(EXAMPLE_URL)
      end

      assert webcache.stores?(EXAMPLE_URL)
    end

    def test_does_not_store
      refute webcache.stores?(EXAMPLE_URL)
    end

    class TestFerrumFetcher < Minitest::Test
      def fetcher
        @fetcher ||= Webcache::FerrumFetcher.new
      end

      def test_fetching
        Ferrum::Browser
          .stubs(:new)
          .returns(
            stub(
              goto: nil,
              network: stub(wait_for_idle: nil),
              body: "Example Domain",
              quit: nil
            )
          )

        body = fetcher.fetch("https://example.com/")

        assert_includes body, "Example Domain"
      end
    end
  end
end
