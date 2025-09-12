# frozen_string_literal: true

module Scouty
  class ScrapeServer
    attr_reader :scraper, :registry, :notifier

    def initialize(scraper:, registry:, notifier:)
      @scraper = scraper
      @registry = registry
      @notifier = notifier
    end

    def serve
      scraper.scrape do |url|
        Retry.run { registry.register_url(url) }
        notifier.notify("scrape.url_found", url:)
      end
    end
  end
end
