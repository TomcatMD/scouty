# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestReviewServer < Minitest::Test
    include TmpDir

    class FakeAssistant
      Report = Data.define(:company, :position, :score, :notes)

      attr_reader :reports

      def initialize
        @reports = {
          "https://example.com/job-a" => Report.new(
            company: "Company A",
            position: "Position A",
            score: 1.23,
            notes: "Notes A"
          ),
          "https://example.com/job-b" => Report.new(
            company: "Company B",
            position: "Position B",
            score: 4.56,
            notes: "Notes B"
          )
        }
      end

      def review(url)
        reports.fetch(url)
      end
    end

    def assistant
      @assistant ||= FakeAssistant.new
    end

    def registry
      @registry ||=
        Registry.new(file: File.join(tmpdir, "registry.db")).tap do |r|
          r.register_url("https://example.com/job-a")
          r.register_url("https://example.com/job-b")
        end
    end

    def notifier
      @notifier ||= Notifier.new(stdout:)
    end

    def stdout
      @stdout ||= StringIO.new
    end

    def server
      @server ||= ReviewServer.new(assistant:, registry:, notifier:)
    end

    def test_execution
      server.serve

      progress = <<~TEXT
        Unscored URL review started ...

        https://example.com/job-a ...
        Company:  Company A
        Position: Position A
        Score:    1.23
        Notes A

        https://example.com/job-b ...
        Company:  Company B
        Position: Position B
        Score:    4.56🔥
        Notes B

        Unscored URL review completed.
      TEXT

      report_a = registry.find_report("https://example.com/job-a")
      report_b = registry.find_report("https://example.com/job-b")

      assert_equal progress, stdout.string

      assert_equal "Company A", report_a.company
      assert_equal "Position A", report_a.position
      assert_in_delta(1.23, report_a.score)
      assert_equal "Notes A", report_a.notes

      assert_equal "Company B", report_b.company
      assert_equal "Position B", report_b.position
      assert_in_delta(4.56, report_b.score)
      assert_equal "Notes B", report_b.notes
    end
  end
end
