# frozen_string_literal: true

module Scouty
  class Retry
    def self.run(base_interval: 1, &)
      Retriable.retriable(tries: 5, base_interval:, multiplier: 2, &)
    end
  end
end
