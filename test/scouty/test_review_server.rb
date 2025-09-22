# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestReviewServer < Minitest::Test
    include TmpDir

    class FakeAssistant
      Review = Data.define(:company, :position, :score, :notes)

      attr_reader :reviews

      def initialize
        @reviews = {
          "https://example.com/job-a" => Review.new(
            company: "Company A",
            position: "Position A",
            score: 1.23,
            notes: "Notes A"
          ),
          "https://example.com/job-b" => Review.new(
            company: "Company B",
            position: "Position B",
            score: 4.56,
            notes: "Notes B"
          )
        }
      end

      def review(url)
        reviews.fetch(url)
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
      @notifier ||= Notifier.new(report: nil, stdout:)
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

      review_a = registry.find_review("https://example.com/job-a")
      review_b = registry.find_review("https://example.com/job-b")

      assert_equal progress, stdout.string

      assert_equal "Company A", review_a.company
      assert_equal "Position A", review_a.position
      assert_in_delta(1.23, review_a.score)
      assert_equal "Notes A", review_a.notes

      assert_equal "Company B", review_b.company
      assert_equal "Position B", review_b.position
      assert_in_delta(4.56, review_b.score)
      assert_equal "Notes B", review_b.notes
    end
  end
end
