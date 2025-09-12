# frozen_string_literal: true

require "test_helper"

module Scouty
  module Scrapers
    class TestJustJoinIT < Minitest::Test
      def scraper
        @scraper ||= JustJoinIT.new(params: { "categories" => %w[ruby javascript] })
      end

      def test_scrape
        stub_request(:get, "https://api.justjoin.it/v2/user-panel/offers/by-cursor")
          .with(query: { categories: [4, 1], from: nil })
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
          .with(query: { categories: [4, 1], from: "next" })
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
          .with(query: { "categories" => [4, 1], "from" => nil })
          .to_return(status: 500, body: "Internal Error")

        err =
          Retry.stub(:run, ->(&block) { block.call }) do
            assert_raises(StandardError) do
              scraper.scrape { "noop" }
            end
          end

        assert_match(/^the server responded with status 500/, err.message)
      end

      def test_without_categories
        scraper = JustJoinIT.new(params: {})

        stub_request(:get, "https://api.justjoin.it/v2/user-panel/offers/by-cursor")
          .with(query: { from: nil })
          .to_return(
            body: JSON.generate(
              {
                data: [
                  { slug: "example-a" }
                ],
                meta: { next: { cursor: nil } }
              }
            )
          )

        urls = []
        scraper.scrape { |u| urls << u }

        assert_equal ["https://justjoin.it/job-offer/example-a"], urls
      end

      def test_category_mapping
        assert_equal 1, JustJoinIT.fetch_category_code("javascript")
        assert_equal 2, JustJoinIT.fetch_category_code("html")
        assert_equal 3, JustJoinIT.fetch_category_code("php")
        assert_equal 4, JustJoinIT.fetch_category_code("ruby")
        assert_equal 5, JustJoinIT.fetch_category_code("python")
        assert_equal 6, JustJoinIT.fetch_category_code("java")
        assert_equal 7, JustJoinIT.fetch_category_code("dotnet")
        assert_equal 8, JustJoinIT.fetch_category_code("scala")
        assert_equal 9, JustJoinIT.fetch_category_code("c")
        assert_equal 10, JustJoinIT.fetch_category_code("mobile")
        assert_equal 11, JustJoinIT.fetch_category_code("testing")
        assert_equal 12, JustJoinIT.fetch_category_code("devops")
        assert_equal 13, JustJoinIT.fetch_category_code("admin")
        assert_equal 14, JustJoinIT.fetch_category_code("ui_ux")
        assert_equal 15, JustJoinIT.fetch_category_code("pm")
        assert_equal 16, JustJoinIT.fetch_category_code("game")
        assert_equal 17, JustJoinIT.fetch_category_code("analytics")
        assert_equal 18, JustJoinIT.fetch_category_code("security")
        assert_equal 19, JustJoinIT.fetch_category_code("data")
        assert_equal 20, JustJoinIT.fetch_category_code("go")
        assert_equal 21, JustJoinIT.fetch_category_code("support")
        assert_equal 22, JustJoinIT.fetch_category_code("erp")
        assert_equal 23, JustJoinIT.fetch_category_code("architecture")
        assert_equal 24, JustJoinIT.fetch_category_code("other")
        assert_equal 25, JustJoinIT.fetch_category_code("ai_ml")
      end
    end
  end
end
