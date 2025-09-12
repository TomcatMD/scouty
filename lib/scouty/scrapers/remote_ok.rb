# frozen_string_literal: true

module Scouty
  module Scrapers
    class RemoteOK
      FEED_URL = "https://remoteok.com/api"

      attr_reader :webcache

      def initialize(webcache:)
        @webcache = webcache
      end

      def scrape(&block)
        items = Retry.run { faraday.get.body }
        items.reject! { |i| !i.key?("url") || i.fetch("company").empty? }

        items.each do |p|
          url = p.fetch("url")
          desc = p.fetch("description")

          webcache.store(url, desc)
          block.call(url)
        end
      end

      private

      def faraday
        @faraday ||=
          Faraday.new(url: FEED_URL) do |builder|
            builder.request :json
            builder.response :json, content_type: nil
            builder.response :raise_error
          end
      end
    end
  end
end
