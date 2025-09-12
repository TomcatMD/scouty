# frozen_string_literal: true

module Scouty
  class Assistant
    attr_reader :webcache, :llm, :profile, :normalizer

    def initialize(webcache:, llm:, profile:)
      @webcache = webcache
      @llm = llm
      @profile = profile
      @normalizer = LLMMesssageNormalizer.new
    end

    def review(url)
      content = webcache.fetch(url)
      content = normalizer.normalize_input(content)
      reply = llm.ask(content, instructions: llm_instructions, temperature: 0.0)
      reply = normalizer.normalize_output(reply)

      Report.from_llm_reply(reply)
    rescue Webcache::FetchError
      Report.webcache_fetch_error
    end

    private

    def llm_instructions
      @llm_instructions ||= <<~MARKDOWN
        You are my personal assistant for reviewing job postings and evaluating their relevance to my profile.

        For each provided job posting (which may come as raw, unprocessed data from job boards and could be incomplete or messy), do the following:

        1. Analyze the content and assess how well it matches my professional background, preferences, and requirements.
        2. Provide a relevance score from **0.0 (not relevant at all or missing data)** to **5.0 (perfect match)**.
        3. Give a clear, concise explanation for the assigned score.

        If the posting is broken, incomplete, or lacks enough data to evaluate, assign a **score of 0.0** and explain what is missing.

        ---

        ## My Professional Profile

        #{profile}

        ---

        ## Output Format

        Return the analysis as a JSON object in the following structure:

        {
          "company": "<detected company name>",
          "position": "<detected job title>",
          "score": <score from 0.0 to 5.0>,
          "notes": "<brief explanation of the score>"
        }
      MARKDOWN
    end

    class Report
      attr_reader :company, :position, :score, :notes

      def initialize(company:, position:, score:, notes:)
        @company = company
        @position = position
        @score = score
        @notes = notes
      end

      class << self
        def webcache_fetch_error
          new(
            company: nil,
            position: nil,
            score: -1,
            notes: "Job posting is not accessible"
          )
        end

        def from_llm_reply(content)
          values = JSON.parse!(content)

          new(
            company: values.fetch("company"),
            position: values.fetch("position"),
            score: values.fetch("score"),
            notes: values.fetch("notes")
          )
        end
      end
    end

    class LLMMesssageNormalizer
      def normalize_input(input)
        result =
          ReverseMarkdown.convert(
            input,
            unknown_tags: :bypass,
            github_flavored: true,
            tag_border: ""
          )

        result.gsub!(/]\(data:image.+\)/i, "](image)")
        result.gsub!("&nbsp;", " ")
        result.strip!
        result += "\n"

        result
      end

      def normalize_output(output)
        result = output.dup

        result.gsub!(%r{^<think>.+</think>}m, "")
        result.strip!
        result.delete_prefix!("```json\n")
        result.delete_suffix!("\n```")

        result
      end
    end
  end
end
