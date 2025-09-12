# frozen_string_literal: true

module Scouty
  module Scrapers
    class NoFluffJobs
      BASE_URL = "https://nofluffjobs.com/job/"
      SEARCH_API_URL = "https://nofluffjobs.com/api/search/posting"

      attr_reader :categories

      def initialize(params:)
        @categories = params["categories"]
      end

      def scrape(&block)
        count = 1

        loop do
          page = Retry.run { fetch_postings_page(page: count) }

          slugs =
            page
            .fetch("postings")
            .map { |i| i.fetch("url") }

          total_pages =
            page
            .fetch("totalPages")

          slugs.each { |i| block.call(build_url_from_slug(i)) }

          break if total_pages <= count

          count += 1
        end
      end

      private

      def faraday
        @faraday ||=
          Faraday.new(url: SEARCH_API_URL) do |builder|
            builder.headers["Content-Type"] = "application/infiniteSearch+json"
            builder.response :json, content_type: nil
            builder.response :raise_error
          end
      end

      def fetch_postings_page(page:)
        params = {
          "pageTo" => page,
          "salaryCurrency" => "EUR",
          "salaryPeriod" => "year"
        }

        criteria = categories.nil? ? {} : { "category" => categories }

        response =
          faraday.post do |r|
            r.params = params
            r.body = JSON.generate({ "criteriaSearch" => criteria })
          end

        response.body
      end

      def build_url_from_slug(slug)
        URI.join(BASE_URL, slug).to_s
      end
    end
  end
end
