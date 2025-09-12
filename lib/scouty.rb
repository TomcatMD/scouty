# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default)

require "yaml"

require_relative "scouty/assistant"
require_relative "scouty/config"
require_relative "scouty/lm_studio_client"
require_relative "scouty/notifier"
require_relative "scouty/registry"
require_relative "scouty/retry"
require_relative "scouty/review_server"
require_relative "scouty/scrape_server"
require_relative "scouty/scrapers"
require_relative "scouty/version"
require_relative "scouty/webcache"

module Scouty
  def self.init(config: nil) = App.new(config:)

  class App
    attr_reader :config

    DEFAULT_CONFIG_FILE = "config.yml"

    def initialize(config: nil)
      @config = config || Config.from_file(DEFAULT_CONFIG_FILE)
    end

    def webcache
      @webcache ||= Webcache.new(dir: config.webcache.dir)
    end

    def registry
      @registry ||= Registry.new(file: config.registry.file)
    end

    def scrapers
      @scrapers ||= Scrapers.from_configs(config.scrapers, webcache:)
    end

    def lm_studio
      @lm_studio ||= LMStudioClient.new(url: config.lm_studio.url, model: config.lm_studio.model)
    end

    def notifier
      @notifier ||= Notifier.new(suppressed: config.notifier.suppressed)
    end

    def profile = config.profile

    def assistant
      @assistant ||= Assistant.new(webcache:, llm: lm_studio, profile:)
    end

    def scrape
      threads = scrapers.map do |s|
        Thread.new { ScrapeServer.new(scraper: s, registry:, notifier:).serve }
      end

      threads.each(&:join)
    end

    def review
      ReviewServer.new(assistant:, registry:, notifier:).serve
    end
  end
end
