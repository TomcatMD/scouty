# frozen_string_literal: true

module Scouty
  module Scrapers
    class JustJoinIT
      BASE_URL = "https://justjoin.it/job-offer/"
      CURSOR_API_URL = "https://api.justjoin.it/v2/user-panel/offers/by-cursor"

      CATEGORY_CODES = {
        "javascript" => 1,
        "html" => 2,
        "php" => 3,
        "ruby" => 4,
        "python" => 5,
        "java" => 6,
        "dotnet" => 7,
        "scala" => 8,
        "c" => 9,
        "mobile" => 10,
        "testing" => 11,
        "devops" => 12,
        "admin" => 13,
        "ui_ux" => 14,
        "pm" => 15,
        "game" => 16,
        "analytics" => 17,
        "security" => 18,
        "data" => 19,
        "go" => 20,
        "support" => 21,
        "erp" => 22,
        "architecture" => 23,
        "other" => 24,
        "ai_ml" => 25
      }.freeze

      def self.fetch_category_code(category) = CATEGORY_CODES.fetch(category)

      attr_reader :categories

      def initialize(params:)
        @categories = params["categories"]
        @job_offers_query = build_job_offers_query
      end

      def scrape(&block)
        cursor = nil

        loop do
          page = Retry.run { fetch_job_offers_page(cursor:) }

          slugs =
            page
            .fetch("data")
            .map { |i| i.fetch("slug") }

          cursor =
            page
            .fetch("meta")
            .fetch("next")
            .fetch("cursor")

          slugs.each { |i| block.call(build_url_from_slug(i)) }

          break if cursor.nil?
        end
      end

      private

      attr_reader :job_offers_query

      def build_job_offers_query
        return {} if categories.nil?

        { categories: categories.map { |i| self.class.fetch_category_code(i) } }
      end

      def fetch_job_offers_page(cursor:)
        faraday.get(nil, job_offers_query.merge(from: cursor)).body
      end

      def faraday
        @faraday ||=
          Faraday.new(url: CURSOR_API_URL) do |builder|
            builder.request :json
            builder.response :json, content_type: nil
            builder.response :raise_error
          end
      end

      def build_url_from_slug(slug)
        URI.join(BASE_URL, slug).to_s
      end
    end
  end
end
