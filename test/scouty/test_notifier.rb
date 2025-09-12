# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestNotifier < Minitest::Test
    def stdout
      @stdout ||= StringIO.new
    end

    def test_print_progress
      notifier = Notifier.new(stdout:)

      url = "https://example.com/job"

      report = stub(
        :report,
        company: "Example Inc.",
        position: "Ruby Developer",
        score: 4.5,
        notes: "Good match!"
      )

      expected = <<~TEXT
        Found: https://example.com/job
        Unscored URL review started ...

        https://example.com/job ...
        Company:  Example Inc.
        Position: Ruby Developer
        Score:    4.5
        Good match!

        Unscored URL review completed.
      TEXT

      notifier.notify("scrape.url_found", url:)
      notifier.notify("review.unscored_url_review_started")
      notifier.notify("review.url_review_started", url:)
      notifier.notify("review.url_review_completed", url:, report:)
      notifier.notify("review.unscored_url_review_completed")

      assert_equal expected, stdout.string
    end

    def test_unknown_notification
      notifier = Notifier.new(stdout:)

      notifier.notify("unknown.example_a", url: "https://example.com")
      notifier.notify("unknown.example_b", foo: "bar")

      expected = <<~TEXT
        [unknown.example_a] {url: "https://example.com"}
        [unknown.example_b] {foo: "bar"}
      TEXT

      assert_equal expected, stdout.string
    end

    def test_supporessed
      notifier = Notifier.new(stdout:, suppressed: true)

      url = "https://example.com/job"

      report = stub(
        :report,
        company: "Example Inc.",
        position: "Ruby Developer",
        score: 4.5,
        notes: "Good match!"
      )

      notifier.notify("scrape.url_found", url:)
      notifier.notify("review.unscored_url_review_started")
      notifier.notify("review.url_review_started", url:)
      notifier.notify("review.url_review_completed", url:, report:)
      notifier.notify("review.unscored_url_review_completed")
      notifier.notify("unknown.example_a", url: "https://example.com")
      notifier.notify("unknown.example_b", foo: "bar")

      assert_empty stdout.string
    end
  end
end
