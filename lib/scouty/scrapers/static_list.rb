# frozen_string_literal: true

module Scouty
  module Scrapers
    class StaticList
      attr_reader :list

      def initialize(params:)
        @list = params.fetch("list").dup.freeze
      end

      def scrape(&) = @list.each(&)
    end
  end
end
