# frozen_string_literal: true

module Scouty
  class Notifier
    attr_reader :report, :suppressed, :stdout, :handlers

    def initialize(report:, suppressed: false, stdout: $stdout)
      @report = report
      @suppressed = suppressed
      @stdout = stdout

      @handlers = {
        "scrape.url_found" => method(:handle_url_found),
        "review.unscored_url_review_started" => method(:handle_unscored_url_review_started),
        "review.unscored_url_review_completed" => method(:handle_unscored_url_review_completed),
        "review.url_review_started" => method(:handle_url_review_started),
        "review.url_review_completed" => method(:handle_url_review_completed),
        "report.generated" => method(:handle_report_generated)
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

    def handle_url_review_completed(review:, **_)
      stdout.puts("Company:  #{review.company}")
      stdout.puts("Position: #{review.position}")
      stdout.puts("Score:    #{review.score}#{"🔥" if review.score >= 2.5}")
      stdout.puts(review.notes)
      stdout.puts
    end

    def handle_report_generated(report:)
      html = HtmlReport.new(filename: self.report)

      html.render(report: report)
      stdout.puts("Report file has been generated at #{html.filename}")
    end

    class HtmlReport
      TOP_JOBS_COUNT = 3

      attr_reader :template, :filename

      def initialize(filename:)
        @template = ERB.new(File.read(File.join(__dir__, "notifier.report.rhtml")))
        @filename = filename
      end

      def render(report:)
        File.write(filename, template.result(binding))
      end

      def company_badge_class(company)
        score = company.top_job_score

        if score >= 3.0
          "high"
        elsif score >= 2.0
          "medium"
        else
          "low"
        end
      end

      def job_badge_class(job)
        score = job.score

        if score >= 3.0
          "bg-success"
        elsif score >= 2.0
          "bg-warning"
        else
          "bg-secondary"
        end
      end

      def top_company_jobs(company)
        company.jobs[0...TOP_JOBS_COUNT]
      end

      def more_company_jobs(company)
        company.jobs[TOP_JOBS_COUNT..] || []
      end

      def more_company_jobs?(company)
        company.jobs.size > TOP_JOBS_COUNT
      end
    end
  end
end
