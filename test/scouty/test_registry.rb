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

    def test_review_submission
      registry.register_url("https://example.com/job-a")
      registry.register_url("https://example.com/job-b")

      review_a = stub(
        company: "Company A",
        position: "Position A",
        score: 1.23,
        notes: "Notes A"
      )

      review_b = stub(
        company: "Company B",
        position: "Position B",
        score: 4.56,
        notes: "Notes B"
      )

      assert_nil registry.find_review("https://example.com/job-a")
      assert_nil registry.find_review("https://example.com/job-b")

      registry.submit_review("https://example.com/job-a", review_a)

      assert_equal_reviews review_a, registry.find_review("https://example.com/job-a")
      assert_nil registry.find_review("https://example.com/job-b")

      registry.submit_review("https://example.com/job-b", review_b)

      assert_equal_reviews review_a, registry.find_review("https://example.com/job-a")
      assert_equal_reviews review_b, registry.find_review("https://example.com/job-b")
    end

    def test_unscored_url
      registry.register_url("https://example.com/job-a")
      registry.register_url("https://example.com/job-b")

      assert_equal "https://example.com/job-a", registry.find_unscored_url
      assert_equal "https://example.com/job-a", registry.find_unscored_url

      registry.submit_review(
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

      registry.submit_review(
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

    def test_report_generation
      registry.register_url("https://example.com/job-a")
      registry.register_url("https://example.com/job-b")
      registry.register_url("https://example.com/job-c")

      registry.submit_review(
        "https://example.com/job-a",
        stub(
          company: "Company A",
          position: "Position A",
          score: 1.23,
          notes: "Notes A"
        )
      )

      registry.submit_review(
        "https://example.com/job-b",
        stub(
          company: "Company B",
          position: "Position B",
          score: 4.56,
          notes: "Notes B"
        )
      )

      registry.submit_review(
        "https://example.com/job-c",
        stub(
          company: "Company B",
          position: "Position B",
          score: 3.56,
          notes: "Notes C"
        )
      )

      report = registry.generate_report

      assert_equal 2, report.companies.size
      assert_equal "Company B", report.companies[0].name
      assert_equal 1, report.companies[0].jobs.size
      assert_equal "Position B", report.companies[0].jobs[0].position
      assert_equal "https://example.com/job-b", report.companies[0].jobs[0].url
      assert_in_delta(4.56, report.companies[0].jobs[0].score)
      assert_equal "Notes B", report.companies[0].jobs[0].notes
      assert_equal "Company A", report.companies[1].name
      assert_equal 1, report.companies[1].jobs.size
      assert_equal "Position A", report.companies[1].jobs[0].position
      assert_equal "https://example.com/job-a", report.companies[1].jobs[0].url
      assert_in_delta(1.23, report.companies[1].jobs[0].score)
      assert_equal "Notes A", report.companies[1].jobs[0].notes
    end

    private

    def assert_equal_reviews(expected, actual)
      %i[company position score notes].each do |i|
        assert_equal expected.send(i), actual.send(i)
      end
    end
  end
end
