# frozen_string_literal: true

module Scouty
  module Scrapers
    class JustJoinIT
      BASE_URL = "https://justjoin.it/job-offer/"
      CURSOR_API_URL = "https://api.justjoin.it/v2/user-panel/offers/by-cursor"

      def scrape(&block)
        cursor = nil

        loop do
          body = Retry.run { faraday.get(nil, from: cursor).body }

          slugs =
            body
            .fetch("data")
            .map { |i| i.fetch("slug") }

          cursor =
            body
            .fetch("meta")
            .fetch("next")
            .fetch("cursor")

          slugs.each { |i| block.call(build_url_from_slug(i)) }

          break if cursor.nil?
        end
      end

      private

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
