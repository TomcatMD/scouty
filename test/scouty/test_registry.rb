# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestRegistry < Minitest::Test
    include TmpDir

    def registry
      @registry ||= Registry.new(file: File.join(tmpdir, "registry.db"))
    end

    def test_url_registration
      registry.register_url("https://example.com/job-a")
      registry.register_url("https://example.com/job-b")
      registry.register_url("https://example.com/job-c")
      registry.unregister_url("https://example.com/job-b")

      assert_equal ["https://example.com/job-a", "https://example.com/job-c"], registry.list_urls
    end

    def test_report_submission
      registry.register_url("https://example.com/job-a")
      registry.register_url("https://example.com/job-b")

      report_a = stub(
        company: "Company A",
        position: "Position A",
        score: 1.23,
        notes: "Notes A"
      )

      report_b = stub(
        company: "Company B",
        position: "Position B",
        score: 4.56,
        notes: "Notes B"
      )

      assert_nil registry.find_report("https://example.com/job-a")
      assert_nil registry.find_report("https://example.com/job-b")

      registry.submit_report("https://example.com/job-a", report_a)

      assert_equal_reports report_a, registry.find_report("https://example.com/job-a")
      assert_nil registry.find_report("https://example.com/job-b")

      registry.submit_report("https://example.com/job-b", report_b)

      assert_equal_reports report_a, registry.find_report("https://example.com/job-a")
      assert_equal_reports report_b, registry.find_report("https://example.com/job-b")
    end

    def test_unscored_url
      registry.register_url("https://example.com/job-a")
      registry.register_url("https://example.com/job-b")

      assert_equal "https://example.com/job-a", registry.find_unscored_url
      assert_equal "https://example.com/job-a", registry.find_unscored_url

      registry.submit_report(
        "https://example.com/job-a",
        stub(
          company: "Company A",
          position: "Position A",
          score: 1.23,
          notes: "Notes A"
        )
      )

      assert_equal "https://example.com/job-b", registry.find_unscored_url
      assert_equal "https://example.com/job-b", registry.find_unscored_url

      registry.submit_report(
        "https://example.com/job-b",
        stub(
          company: "Company B",
          position: "Position B",
          score: 4.56,
          notes: "Notes B"
        )
      )

      assert_nil registry.find_unscored_url
    end

    private

    def assert_equal_reports(expected, actual)
      %i[company position score notes].each do |i|
        assert_equal expected.send(i), actual.send(i)
      end
    end
  end
end
