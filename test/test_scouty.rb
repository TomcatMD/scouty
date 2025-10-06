# frozen_string_literal: true

require "test_helper"

class TestScouty < Minitest::Test
  include TmpDir

  def scouty
    @scouty ||=
      Scouty.init(config: Scouty::Config.from_yaml(<<~STRING))
        webcache:
          dir: #{File.join(tmpdir, "webcache/")}

        registry:
          file: #{File.join(tmpdir, "registry.db")}

        scrapers:
          - source: list
            list:
              - https://example.com/job/ruby-developer.html
              - https://example.com/job/elixir-developer.html

        notifier:
          hot_score: 2.5
          report: #{File.join(tmpdir, "report.html")}
          suppressed: true

        lm_studio:
          url: "http://127.0.0.1:1234"
          model: "openai/gpt-oss-20b"

        profile: |
          I like Ruby
      STRING
  end

  def test_scrape
    scouty.scrape

    expected = [
      "https://example.com/job/ruby-developer.html",
      "https://example.com/job/elixir-developer.html"
    ]

    assert_equal expected, scouty.registry.list_urls
  end

  def test_review
    scouty.registry.register_url("https://example.com/job/ruby-developer.html")

    scouty.webcache.store("https://example.com/job/ruby-developer.html", <<~TEXT)
      TechNova Solutions looks for a skilled Ruby Developer! You will work on
      building and maintaining web applications, collaborating with
      cross-functional teams, and writing clean, efficient code. Experience with
      Ruby on Rails and SQL databases is a plus.
    TEXT

    scouty.registry.register_url("https://example.com/job/elixir-developer.html")

    scouty.webcache.store("https://example.com/job/elixir-developer.html", <<~TEXT)
      TechNova Solutions looks for a skilled Elixir Developer! You will work on
      building and maintaining web applications, collaborating with
      cross-functional teams, and writing clean, efficient code. Experience with
      Phoenix and Ecto is a plus.
    TEXT

    VCR.use_cassette("test_scouty/test_review") do
      scouty.review
    end

    review_a = scouty.registry.find_review("https://example.com/job/ruby-developer.html")
    review_b = scouty.registry.find_review("https://example.com/job/elixir-developer.html")

    assert_equal "TechNova Solutions", review_a.company
    assert_equal "Ruby Developer", review_a.position
    assert_in_delta(4.5, review_a.score)
    assert_equal <<~TEXT.split.join(" "), review_a.notes
      The posting explicitly seeks a Ruby developer, aligning well with the
      user’s preference for Ruby. It mentions Rails and SQL, which are common in
      Ruby roles, but lacks details on other preferences or requirements that
      might further refine relevance.
    TEXT

    assert_equal "TechNova Solutions", review_b.company
    assert_equal "Elixir Developer", review_b.position
    assert_in_delta 0.0, review_b.score
    assert_equal <<~TEXT.split.join(" "), review_b.notes
      The role focuses on Elixir, Phoenix, and Ecto, while the user’s stated
      preference is Ruby. No overlap in technology stack or experience.
    TEXT
  end

  def test_report
    scouty
      .notifier
      .expects(:notify)
      .with("report.generated", report: anything)

    scouty.report
  end
end
