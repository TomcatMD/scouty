# frozen_string_literal: true

require "test_helper"

module Scouty
  module Scrapers
    class TestRemoteOK < Minitest::Test
      include TmpDir

      def webcache
        @webcache ||= Webcache.new(dir: tmpdir)
      end

      def scraper
        @scraper ||= RemoteOK.new(webcache:)
      end

      def test_scrape
        stub_request(:get, "https://remoteok.com/api")
          .to_return(
            body: JSON.generate(
              [
                {
                  "url" => "https://remoteOK.com/remote-jobs/example-a",
                  "company" => "Company A",
                  "description" => "Description A"
                },
                {
                  "url" => "https://remoteOK.com/remote-jobs/example-b",
                  "company" => "Company B",
                  "description" => "Description B"
                },
                {
                  "url" => "https://remoteOK.com/remote-jobs/example-c",
                  "company" => "Company C",
                  "description" => "Description C"
                }
              ]
            )
          )

        urls = []
        scraper.scrape { |u| urls << u }

        expected = [
          "https://remoteOK.com/remote-jobs/example-a",
          "https://remoteOK.com/remote-jobs/example-b",
          "https://remoteOK.com/remote-jobs/example-c"
        ]

        assert_equal expected, urls
        assert_equal "Description A", webcache.fetch("https://remoteOK.com/remote-jobs/example-a")
        assert_equal "Description B", webcache.fetch("https://remoteOK.com/remote-jobs/example-b")
        assert_equal "Description C", webcache.fetch("https://remoteOK.com/remote-jobs/example-c")
      end

      def test_failure
        stub_request(:get, "https://remoteok.com/api")
          .to_return(status: 500, body: "Internal Errror")

        err =
          Retry.stub(:run, ->(&b) { b.call }) do
            assert_raises(StandardError) do
              scraper.scrape { "noop" }
            end
          end

        assert_match(/^the server responded with status 500/, err.message)
      end

      def test_empty_postings
        stub_request(:get, "https://remoteok.com/api")
          .to_return(
            body: JSON.generate(
              [
                {
                  "company" => "Company A",
                  "description" => "Description A"
                },
                {
                  "url" => "https://remoteOK.com/remote-jobs/example-b",
                  "company" => "",
                  "description" => "Description B"
                },
                {
                  "url" => "https://remoteOK.com/remote-jobs/example-c",
                  "company" => "Company C",
                  "description" => "Example C"
                }
              ]
            )
          )

        urls = []
        scraper.scrape { |u| urls << u }

        assert_equal ["https://remoteOK.com/remote-jobs/example-c"], urls
        refute webcache.stores?("https://remoteOK.com/remote-jobs/example-b")
        assert_equal "Example C", webcache.fetch("https://remoteOK.com/remote-jobs/example-c")
      end
    end
  end
end
