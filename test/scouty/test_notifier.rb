# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestNotifier < Minitest::Test
    include TmpDir

    def stdout
      @stdout ||= StringIO.new
    end

    def report_filename
      @report_filename ||= File.join(tmpdir, "report.html")
    end

    def notifier
      @notifier ||= Notifier.new(report: report_filename, stdout:)
    end

    def test_print_progress
      url = "https://example.com/job"

      review = stub(
        :review,
        company: "Example Inc.",
        position: "Ruby Developer",
        score: 4.5,
        notes: "Good match!"
      )

      report = stub(
        :report,
        companies: [
          stub(
            :company,
            name: "Example Inc.",
            top_job_score: 4.5,
            jobs: [
              stub(
                :job,
                url: "https://example.com/job",
                position: "Ruby Developer",
                score: 4.5,
                notes: "Good match!"
              )
            ]
          )
        ]
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
        Report file has been generated at #{report_filename}
      TEXT

      notifier.notify("scrape.url_found", url:)
      notifier.notify("review.unscored_url_review_started")
      notifier.notify("review.url_review_started", url:)
      notifier.notify("review.url_review_completed", url:, review:)
      notifier.notify("review.unscored_url_review_completed")
      notifier.notify("report.generated", report:)

      assert_equal expected, stdout.string
      assert_path_exists report_filename
    end

    def test_review_completed_flame
      url_a = "https://example.com/job-a"
      review_a = stub(
        :review,
        company: "Company A",
        position: "Position A",
        score: 2.5,
        notes: "Hot match!"
      )

      url_b = "https://example.com/job-b"
      review_b = stub(
        :review,
        company: "Company B",
        position: "Position B",
        score: 2.0,
        notes: "Regular match."
      )

      notifier.notify("review.url_review_completed", url: url_a, review: review_a)
      notifier.notify("review.url_review_completed", url: url_b, review: review_b)

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
      notifier = Notifier.new(
        report: report_filename,
        suppressed: true,
        stdout:
      )

      url = "https://example.com/job"

      review = stub(
        :review,
        company: "Example Inc.",
        position: "Ruby Developer",
        score: 4.5,
        notes: "Good match!"
      )

      notifier.notify("scrape.url_found", url:)
      notifier.notify("review.unscored_url_review_started")
      notifier.notify("review.url_review_started", url:)
      notifier.notify("review.url_review_completed", url:, review:)
      notifier.notify("review.unscored_url_review_completed")
      notifier.notify("unknown.example_a", url: "https://example.com")
      notifier.notify("unknown.example_b", foo: "bar")

      assert_empty stdout.string
      refute_path_exists report_filename
    end

    class TestHtmlReport < Minitest::Test
      include TmpDir

      def filename
        @filename ||= File.join(tmpdir, "report.html")
      end

      def html_report
        @html_report ||= Notifier::HtmlReport.new(filename:)
      end

      def test_render
        html_report.render(
          report: stub(
            :report,
            companies: [
              stub(
                :company,
                name: "Company",
                top_job_score: 4.56,
                jobs: []
              )
            ]
          )
        )

        assert_path_exists filename
      end

      def test_company_badge_class
        assert_equal "high", html_report.company_badge_class(stub(:company, top_job_score: 3.45))
        assert_equal "high", html_report.company_badge_class(stub(:company, top_job_score: 3.0))
        assert_equal "medium", html_report.company_badge_class(stub(:company, top_job_score: 2.99))
        assert_equal "medium", html_report.company_badge_class(stub(:company, top_job_score: 2.0))
        assert_equal "low", html_report.company_badge_class(stub(:company, top_job_score: 1.99))
        assert_equal "low", html_report.company_badge_class(stub(:company, top_job_score: 0.0))
      end

      def test_job_badge_class
        assert_equal "bg-success", html_report.job_badge_class(stub(:job, score: 3.45))
        assert_equal "bg-success", html_report.job_badge_class(stub(:job, score: 3.0))
        assert_equal "bg-warning", html_report.job_badge_class(stub(:job, score: 2.99))
        assert_equal "bg-warning", html_report.job_badge_class(stub(:job, score: 2.0))
        assert_equal "bg-secondary", html_report.job_badge_class(stub(:job, score: 1.99))
        assert_equal "bg-secondary", html_report.job_badge_class(stub(:job, score: 0.0))
      end

      def test_top_company_jobs
        assert_empty [], html_report.top_company_jobs(stub(:company, jobs: []))
        assert_equal [1], html_report.top_company_jobs(stub(:company, jobs: [1]))
        assert_equal [1, 2, 3], html_report.top_company_jobs(stub(:company, jobs: [1, 2, 3]))
        assert_equal [1, 2, 3], html_report.top_company_jobs(stub(:company, jobs: [1, 2, 3, 4]))
      end

      def test_more_company_jobs
        assert_empty html_report.more_company_jobs(stub(:company, jobs: []))
        assert_empty html_report.more_company_jobs(stub(:company, jobs: [1]))
        assert_empty html_report.more_company_jobs(stub(:company, jobs: [1, 2, 3]))
        assert_equal [4], html_report.more_company_jobs(stub(:company, jobs: [1, 2, 3, 4]))
        assert_equal [4, 5], html_report.more_company_jobs(stub(:company, jobs: [1, 2, 3, 4, 5]))
      end

      def test_more_company_jobs?
        refute html_report.more_company_jobs?(stub(:company, jobs: [1]))
        refute html_report.more_company_jobs?(stub(:company, jobs: [1, 2]))
        refute html_report.more_company_jobs?(stub(:company, jobs: [1, 2, 3]))
        assert html_report.more_company_jobs?(stub(:company, jobs: [1, 2, 3, 4]))
        assert html_report.more_company_jobs?(stub(:company, jobs: [1, 2, 3, 4, 5]))
      end
    end
  end
end
