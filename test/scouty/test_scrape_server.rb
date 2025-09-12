# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestScrapeServer < Minitest::Test
    include TmpDir

    JOB_URL_EXAMPLES = [
      "https://example.com/job-a",
      "https://example.com/job-b",
      "https://example.com/job-c"
    ].freeze

    def scraper
      @scraper ||= Scrapers::StaticList.new(params: { "list" => JOB_URL_EXAMPLES })
    end

    def registry
      @registry ||= Registry.new(file: File.join(tmpdir, "registry.db"))
    end

    def notifier
      @notifier ||= Notifier.new(stdout:)
    end

    def stdout
      @stdout ||= StringIO.new
    end

    def server
      @server ||= ScrapeServer.new(scraper:, registry:, notifier:)
    end

    def test_execution
      server.serve

      progress = <<~TEXT
        Found: https://example.com/job-a
        Found: https://example.com/job-b
        Found: https://example.com/job-c
      TEXT

      assert_equal progress, stdout.string
      assert_equal JOB_URL_EXAMPLES, registry.list_urls
    end
  end
end
