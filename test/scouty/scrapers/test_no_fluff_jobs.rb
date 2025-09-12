# frozen_string_literal: true

require "test_helper"

module Scouty
  module Scrapers
    class TestNoFluffJobs < Minitest::Test
      def scraper
        @scraper ||= NoFluffJobs.new(params: { "categories" => ["backend"] })
      end

      def test_scrape
        stub_request(:post, "https://nofluffjobs.com/api/search/posting")
          .with(
            query: {
              "pageTo" => 1,
              "salaryCurrency" => "EUR",
              "salaryPeriod" => "year"
            },
            headers: {
              "Content-Type" => "application/infiniteSearch+json"
            },
            body: { "criteriaSearch" => { "category" => ["backend"] } }
          )
          .to_return(
            body: JSON.generate(
              {
                "postings" => [
                  { "url" => "example-a" },
                  { "url" => "example-b" }
                ],
                "totalPages" => 2
              }
            )
          )

        stub_request(:post, "https://nofluffjobs.com/api/search/posting")
          .with(
            query: {
              "pageTo" => 2,
              "salaryCurrency" => "EUR",
              "salaryPeriod" => "year"
            },
            headers: {
              "Content-Type" => "application/infiniteSearch+json"
            },
            body: { "criteriaSearch" => { "category" => ["backend"] } }
          )
          .to_return(
            body: JSON.generate(
              {
                "postings" => [
                  { "url" => "example-c" }
                ],
                "totalPages" => 2
              }
            )
          )

        urls = []
        scraper.scrape { |u| urls << u }

        expected = [
          "https://nofluffjobs.com/job/example-a",
          "https://nofluffjobs.com/job/example-b",
          "https://nofluffjobs.com/job/example-c"
        ]

        assert_equal expected, urls
      end

      def test_failure
        stub_request(:post, "https://nofluffjobs.com/api/search/posting")
          .with(
            query: {
              "pageTo" => 1,
              "salaryCurrency" => "EUR",
              "salaryPeriod" => "year"
            },
            headers: {
              "Content-Type" => "application/infiniteSearch+json"
            },
            body: { "criteriaSearch" => { "category" => ["backend"] } }
          )
          .to_return(status: 500, body: "Internal Error")

        err =
          Retry.stub(:run, ->(&b) { b.call }) do
            assert_raises(StandardError) do
              scraper.scrape { "noop" }
            end
          end

        assert_match(/^the server responded with status 500/, err.message)
      end

      def test_without_categories
        scraper = NoFluffJobs.new(params: {})

        stub_request(:post, "https://nofluffjobs.com/api/search/posting")
          .with(
            query: {
              "pageTo" => 1,
              "salaryCurrency" => "EUR",
              "salaryPeriod" => "year"
            },
            headers: {
              "Content-Type" => "application/infiniteSearch+json"
            },
            body: { "criteriaSearch" => {} }
          )
          .to_return(
            body: JSON.generate(
              {
                "postings" => [
                  { "url" => "example" }
                ],
                "totalPages" => 1
              }
            )
          )

        urls = []
        scraper.scrape { |u| urls << u }

        assert_equal ["https://nofluffjobs.com/job/example"], urls
      end
    end
  end
end
