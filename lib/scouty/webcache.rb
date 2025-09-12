# frozen_string_literal: true

module Scouty
  class Webcache
    class FetchError < StandardError; end

    attr_reader :dir

    def initialize(dir:)
      @dir = dir
    end

    def fetch(url)
      filename = evaluate_cache_filename(url)

      content = read_cache(filename)
      return content unless content.nil?

      content = fetch_by_web_request(url)
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

    def fetch_by_web_request(url)
      response = Faraday.get(url)

      raise FetchError if [308, 404].include?(response.status)
      raise "Unexpected response #{response.status}\n#{response.body}" unless response.status == 200

      response.body
    end
  end
end
