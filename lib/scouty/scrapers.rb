# frozen_string_literal: true

require_relative "scrapers/just_join_it"
require_relative "scrapers/no_fluff_jobs"
require_relative "scrapers/remote_ok"
require_relative "scrapers/static_list"

module Scouty
  module Scrapers
    class << self
      def from_configs(configs, webcache:)
        configs.map { |c| init(c.source, webcache:, params: c.params) }
      end

      def init(source, webcache:, params: {})
        case source
        when "list"
          StaticList.new(params:)
        when "justjoin.it"
          JustJoinIT.new
        when "nofluffjobs.com"
          NoFluffJobs.new(params:)
        when "remoteok.com"
          RemoteOK.new(webcache:)
        else
          raise ArgumentError, "unknown source for scraping: #{source}"
        end
      end
    end
  end
end
