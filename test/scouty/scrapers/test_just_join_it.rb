# frozen_string_literal: true

require "test_helper"

module Scouty
  module Scrapers
    class TestJustJoinIT < Minitest::Test
      def scraper
        @scraper ||= JustJoinIT.new
      end

      def test_scrape
        stub_request(:get, "https://api.justjoin.it/v2/user-panel/offers/by-cursor")
          .with(query: { from: nil })
          .to_return(
            body: JSON.generate(
              {
                data: [
                  { slug: "example-a" },
                  { slug: "example-b" }
                ],
                meta: { next: { cursor: "next" } }
              }
            )
          )

        stub_request(:get, "https://api.justjoin.it/v2/user-panel/offers/by-cursor")
          .with(query: { from: "next" })
          .to_return(
            body: JSON.generate(
              {
                data: [
                  { slug: "example-c" }
                ],
                meta: { next: { cursor: nil } }
              }
            )
          )

        urls = []
        scraper.scrape { |u| urls << u }

        expected = [
          "https://justjoin.it/job-offer/example-a",
          "https://justjoin.it/job-offer/example-b",
          "https://justjoin.it/job-offer/example-c"
        ]

        assert_equal expected, urls
      end

      def test_failure
        stub_request(:get, "https://api.justjoin.it/v2/user-panel/offers/by-cursor")
          .with(query: { from: nil })
          .to_return(status: 500, body: "Internal Error")

        err =
          Retry.stub(:run, ->(&block) { block.call }) do
            assert_raises(StandardError) do
              scraper.scrape { "noop" }
            end
          end

        assert_match(/^the server responded with status 500/, err.message)
      end
    end
  end
end
