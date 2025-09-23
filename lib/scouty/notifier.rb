# frozen_string_literal: true

module Scouty
  class Notifier
    class << self
      def from_config(config)
        telegram =
          unless config.telegram.nil?
            Telegram.new(
              token: config.telegram.token,
              chat_id: config.telegram.chat_id
            )
          end

        new(
          hot_score: config.hot_score,
          telegram:,
          report: config.report,
          suppressed: config.suppressed
        )
      end
    end

    attr_reader :hot_score, :telegram, :report, :suppressed, :stdout, :handlers

    def initialize(hot_score:, telegram:, report:, suppressed: false, stdout: $stdout)
      @hot_score = hot_score
      @telegram = telegram
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

    def handle_url_review_completed(url:, review:)
      stdout.puts(<<~TEXT)
        Company:  #{review.company}
        Position: #{review.position}
        Score:    #{review.score}#{"🔥" if review.score >= hot_score}
        #{review.notes}

      TEXT

      telegram&.send_message(<<~TEXT) if review.score >= hot_score
        #{url}

        #{review.company}
        #{review.position}

        Score: #{review.score} 🔥
        #{review.notes}
      TEXT
    end

    def handle_report_generated(report:)
      html = HtmlReport.new(filename: self.report, hot_score:)

      html.render(report: report)
      stdout.puts("Report file has been generated at #{html.filename}")

      telegram&.send_message("New report is ready and awaits your review.")
    end

    class HtmlReport
      TOP_JOBS_COUNT = 3

      attr_reader :template, :filename, :hot_score

      def initialize(filename:, hot_score:)
        @template = ERB.new(File.read(File.join(__dir__, "notifier.report.rhtml")))
        @filename = filename
        @hot_score = hot_score
      end

      def render(report:)
        File.write(filename, template.result(binding))
      end

      def company_badge_class(company)
        score = company.top_job_score

        if hot_score?(score)
          "high"
        elsif almost_hot_score?(score)
          "medium"
        else
          "low"
        end
      end

      def job_badge_class(job)
        score = job.score

        if hot_score?(score)
          "bg-success"
        elsif almost_hot_score?(score)
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

      private

      def hot_score?(score)
        score >= hot_score
      end

      def almost_hot_score?(score)
        score >= 0.5 * hot_score
      end
    end

    class Telegram
      attr_reader :token, :chat_id, :client

      def initialize(token:, chat_id:)
        @token = token
        @chat_id = chat_id
        @client = ::Telegram::Bot::Client.new(token)
      end

      def send_message(text)
        client.api.send_message(chat_id:, text:)
      end
    end
  end
end
