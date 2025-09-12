# frozen_string_literal: true

module Scouty
  class ReviewServer
    attr_reader :assistant, :registry, :notifier

    def initialize(assistant:, registry:, notifier:)
      @assistant = assistant
      @registry = registry
      @notifier = notifier
    end

    def serve
      notifier.notify("review.unscored_url_review_started")

      loop do
        url = find_unscored_url
        break if url.nil?

        notifier.notify("review.url_review_started", url:)
        report = review_url(url)
        notifier.notify("review.url_review_completed", url:, report:)
      end

      notifier.notify("review.unscored_url_review_completed")
    end

    private

    def find_unscored_url
      Retry.run { registry.find_unscored_url }
    end

    def review_url(url)
      report = Retry.run { assistant.review(url) }
      Retry.run { registry.submit_report(url, report) }

      report
    end
  end
end
