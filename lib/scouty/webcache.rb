# frozen_string_literal: true

module Scouty
  class Webcache
    attr_reader :dir, :fetcher

    def initialize(dir:)
      @dir = dir
      @fetcher = FerrumFetcher.new
    end

    def fetch(url)
      filename = evaluate_cache_filename(url)

      content = read_cache(filename)
      return content unless content.nil?

      content = fetcher.fetch(url)
      write_cache(filename, content)

      content
    end

    def store(url, content)
      write_cache(evaluate_cache_filename(url), content)
    end

    def stores?(url)
      File.exist?(evaluate_cache_filename(url))
    end

    private

    def evaluate_cache_filename(url)
      uri = URI.parse(url)
      File.join(dir, uri.host, "#{uri.path}.html")
    end

    def read_cache(filename)
      File.exist?(filename) ? File.read(filename) : nil
    end

    def write_cache(filename, content)
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, content)
    end

    class FerrumFetcher
      def fetch(url)
        browser = Ferrum::Browser.new(timeout: 30)

        browser.goto(url)
        browser.network.wait_for_idle
        html = browser.body
        browser.quit

        html
      end
    end
  end
end
