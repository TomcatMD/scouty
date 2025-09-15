# frozen_string_literal: true

module Scouty
  class Notifier
    attr_reader :stdout, :suppressed, :handlers

    def initialize(stdout: $stdout, suppressed: false)
      @stdout = stdout
      @suppressed = suppressed

      @handlers = {
        "scrape.url_found" => method(:handle_url_found),
        "review.unscored_url_review_started" => method(:handle_unscored_url_review_started),
        "review.unscored_url_review_completed" => method(:handle_unscored_url_review_completed),
        "review.url_review_started" => method(:handle_url_review_started),
        "review.url_review_completed" => method(:handle_url_review_completed)
      }
    end

    def notify(status, **kvargs)
      return if suppressed

      handler = handlers[status]

      if handler
        handler.call(**kvargs)
      else
        stdout.puts("[#{status}] #{kvargs}")
      end
    end

    private

    def handle_url_found(url:)
      stdout.puts("Found: #{url}")
    end

    def handle_unscored_url_review_started
      stdout.puts("Unscored URL review started ...")
      stdout.puts
    end

    def handle_unscored_url_review_completed
      stdout.puts("Unscored URL review completed.")
    end

    def handle_url_review_started(url:)
      stdout.puts("#{url} ...")
    end

    def handle_url_review_completed(report:, **_)
      stdout.puts("Company:  #{report.company}")
      stdout.puts("Position: #{report.position}")
      stdout.puts("Score:    #{report.score}#{"🔥" if report.score >= 2.5}")
      stdout.puts(report.notes)
      stdout.puts
    end
  end
end
