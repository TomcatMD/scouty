# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestNotifier < Minitest::Test
    def stdout
      @stdout ||= StringIO.new
    end

    def notifier
      @notifier ||= Notifier.new(stdout:)
    end

    def test_print_progress
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
        Score:    4.5🔥
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

    def test_review_completed_flame
      url_a = "https://example.com/job-a"
      report_a = stub(
        :report,
        company: "Company A",
        position: "Position A",
        score: 2.5,
        notes: "Hot match!"
      )

      url_b = "https://example.com/job-b"
      report_b = stub(
        :report,
        company: "Company B",
        position: "Position B",
        score: 2.0,
        notes: "Regular match."
      )

      notifier.notify("review.url_review_completed", url: url_a, report: report_a)
      notifier.notify("review.url_review_completed", url: url_b, report: report_b)

      expected = <<~TEXT
        Company:  Company A
        Position: Position A
        Score:    2.5🔥
        Hot match!

        Company:  Company B
        Position: Position B
        Score:    2.0
        Regular match.

      TEXT

      assert_equal expected, stdout.string
    end

    def test_unknown_notification
      notifier.notify("unknown.example_a", url: "https://example.com")
      notifier.notify("unknown.example_b", foo: "bar")

      expected = <<~TEXT
        [unknown.example_a] {url: "https://example.com"}
        [unknown.example_b] {foo: "bar"}
      TEXT

      assert_equal expected, stdout.string
    end

    def test_suppressed
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
