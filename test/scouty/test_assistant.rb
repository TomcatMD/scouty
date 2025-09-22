# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestAssistant < Minitest::Test
    def webcache
      @webcache ||= mock(:webcache)
    end

    def llm
      @llm ||= mock(:llm)
    end

    def profile = "I'm a Ruby developer"

    def assistant
      @assistant ||= Assistant.new(webcache:, llm:, profile:)
    end

    def test_review_success
      webcache
        .expects(:fetch)
        .with("https://example.com/ruby-dev")
        .returns("Example hires Ruby Developer")

      llm
        .expects(:ask)
        .with("Example hires Ruby Developer\n", instructions: includes(profile), temperature: 0.0)
        .returns(<<~JSON)
          {
            "company": "Example Inc.",
            "position": "Ruby Developer",
            "score": 4.5,
            "notes": "Strong match!"
          }
        JSON

      review = assistant.review("https://example.com/ruby-dev")

      assert_equal "Example Inc.", review.company
      assert_equal "Ruby Developer", review.position
      assert_in_delta 4.5, review.score
      assert_equal "Strong match!", review.notes
    end

    def test_review_fetch_error
      webcache
        .expects(:fetch)
        .raises(Webcache::FetchError)

      llm.expects(:ask).never

      review = assistant.review("https://example.com/ruby-dev")

      assert_nil review.company
      assert_nil review.position
      assert_equal(-1, review.score)
      assert_equal "Job posting is not accessible", review.notes
    end

    def test_input_normalization
      webcache
        .expects(:fetch)
        .with("https://example.com/ruby-dev")
        .returns(<<~HTML)
          <b>Example Inc. hires a Ruby Developer!</b>
          <ul>
            <li>Ruby experience 5+ years is required</li>
            <li>LLM experience is required</li>
          </ul>
        HTML

      llm
        .expects(:ask)
        .with(<<~MARKDOWN, instructions: anything, temperature: anything)
          **Example Inc. hires a Ruby Developer!**
          - Ruby experience 5+ years is required
          - LLM experience is required
        MARKDOWN
        .returns(<<~JSON)
          {
            "company": "Example Inc.",
            "position": "Ruby Developer",
            "score": 4.5,
            "notes": "Strong match!"
          }
        JSON

      assistant.review("https://example.com/ruby-dev")
    end

    def test_output_normalization
      webcache
        .expects(:fetch)
        .returns("Example hires Ruby Developer")

      llm
        .expects(:ask)
        .returns(<<~TEXT)
          <think>LLM thinks about something</think>
          ```json
          {
            "company": "Example Inc.",
            "position": "Ruby Developer",
            "score": 4.5,
            "notes": "Strong match!"
          }
          ```
        TEXT

      review = assistant.review("https://example.com/ruby-dev")

      assert_equal "Example Inc.", review.company
      assert_equal "Ruby Developer", review.position
      assert_in_delta(4.5, review.score)
      assert_equal "Strong match!", review.notes
    end

    class TestLLMMessageNormalizer < Minitest::Test
      def normalizer
        @normalizer ||= Assistant::LLMMesssageNormalizer.new
      end

      def test_input_html
        input = <<~HTML
          <h1>Ruby Developer</h1>
          <p><strong>Company:</strong> CodeWorks</p>
          <p><strong>Location:</strong> Remote</p>

          <h2>Responsibilities</h2>
          <ul>
            <li>Develop and maintain Ruby on Rails applications</li>
            <li>Write clean, maintainable code</li>
            <li>Work with databases and APIs</li>
          </ul>

          <h2>Requirements</h2>
          <ul>
            <li>2+ years with Ruby/Rails</li>
            <li>Experience with PostgreSQL</li>
            <li>Familiarity with Git</li>
          </ul>
        HTML

        normalized = <<~MARKDOWN
          # Ruby Developer

          **Company:** CodeWorks

          **Location:** Remote

          ## Responsibilities

          - Develop and maintain Ruby on Rails applications
          - Write clean, maintainable code
          - Work with databases and APIs

          ## Requirements

          - 2+ years with Ruby/Rails
          - Experience with PostgreSQL
          - Familiarity with Git
        MARKDOWN

        assert_equal normalized, normalizer.normalize_input(input)
      end

      def test_input_embedded_images
        input = <<~HTML
          <h1>Python Developer</h1>
          <p><strong>Company:</strong> DataCorp</p>
          <p><strong>Location:</strong> Remote</p>

          <img
            src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAn8B9Q4PpQEAAAAASUVORK5CYII="
            alt="Company Logo"
          />

          <h2>Responsibilities</h2>
          <ul>
            <li>Develop backend services in Python</li>
            <li>Integrate APIs and databases</li>
            <li>Write unit and integration tests</li>
          </ul>
        HTML

        normalized = <<~MARKDOWN
          # Python Developer

          **Company:** DataCorp

          **Location:** Remote

           ![Company Logo](image)
          ## Responsibilities

          - Develop backend services in Python
          - Integrate APIs and databases
          - Write unit and integration tests
        MARKDOWN

        assert_equal normalized, normalizer.normalize_input(input)
      end

      def test_input_nbsp
        result = normalizer.normalize_input("&nbsp;We&nbsp;are&nbsp;hiring!&nbsp;")

        assert_equal "We are hiring!\n", result
      end

      def test_output_think
        output = <<~TEXT
          <think>LLM thinks about something</think>
          { "company": "Example Inc.", "position": "Ruby Developer", "score": 4.5, "notes": "Strong match!" }
        TEXT

        normalized = <<~JSON.strip
          { "company": "Example Inc.", "position": "Ruby Developer", "score": 4.5, "notes": "Strong match!" }
        JSON

        assert_equal normalized, normalizer.normalize_output(output)
      end

      def test_output_markdown_json_tags
        output = <<~MARKDOWN
          ```json
          { "company": "Example Inc.", "position": "Ruby Developer", "score": 4.5, "notes": "Strong match!" }
          ```
        MARKDOWN

        normalized = <<~JSON.strip
          { "company": "Example Inc.", "position": "Ruby Developer", "score": 4.5, "notes": "Strong match!" }
        JSON

        assert_equal normalized, normalizer.normalize_output(output)
      end
    end
  end
end
