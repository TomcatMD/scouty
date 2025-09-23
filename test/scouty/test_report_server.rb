# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestReportServer < Minitest::Test
    include TmpDir

    def report_filename
      @report_filename ||= File.join(tmpdir, "report.html")
    end

    def stdout
      @stdout ||= StringIO.new
    end

    def registry
      @registry ||= Registry.new(file: File.join(tmpdir, "registry.db"))
    end

    def notifier
      @notifier ||= Notifier.new(hot_score: 2.5, telegram: nil, report: report_filename, stdout:)
    end

    def server
      @server ||= ReportServer.new(registry:, notifier:)
    end

    def test_execution
      server.serve

      progress = <<~TEXT
        Report file has been generated at #{report_filename}
      TEXT

      assert_equal progress, stdout.string
      assert_path_exists report_filename
    end
  end
end
