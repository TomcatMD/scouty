# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestConfig < Minitest::Test
    include TmpDir

    EXAMPLE = <<~TEXT
      webcache:
        dir: /a/b/c/

      registry:
        file: /a/b/c/d.db

      scrapers:
        - source: example-a.com
          param_a: Value A
          param_b: Value B
        - source: example-b.com
          param_c: Value C
        - source: example-c.com

      notifier:
        suppressed: true

      lm_studio:
        url: "http://127.0.0.1:1234"
        model: "openai/gpt-oss-20b"

      profile: I like Ruby
    TEXT

    def test_load_from_yaml
      config = Config.from_yaml(EXAMPLE)

      assert_equal "/a/b/c/", config.webcache.dir

      assert_equal "/a/b/c/d.db", config.registry.file
      assert_equal "/a/b/c/d.db", config.registry.file

      assert_equal "example-a.com", config.scrapers[0].source
      assert_equal({ "param_a" => "Value A", "param_b" => "Value B" }, config.scrapers[0].params)
      assert_equal "example-b.com", config.scrapers[1].source
      assert_equal({ "param_c" => "Value C" }, config.scrapers[1].params)
      assert_equal "example-c.com", config.scrapers[2].source
      assert_empty(config.scrapers[2].params)

      assert_same true, config.notifier.suppressed

      assert_equal "http://127.0.0.1:1234", config.lm_studio.url
      assert_equal "openai/gpt-oss-20b", config.lm_studio.model

      assert_equal "I like Ruby", config.profile
    end

    def test_default_values
      example_without_notifier = YAML.dump(YAML.load(EXAMPLE).except("notifier"))
      config = Config.from_yaml(example_without_notifier)

      assert_same false, config.notifier.suppressed
    end

    def test_missing_parameter
      broken = YAML.load(EXAMPLE)
      broken["lm_studio"].delete("model")

      err = assert_raises(KeyError) { Config.from_yaml(YAML.dump(broken)) }
      assert_equal "configuration value not found: lm_studio.model", err.message
    end

    def test_invalid_scrapers_value
      broken = YAML.load(EXAMPLE)
      broken["scrapers"] = { "foo" => "bar" }

      err = assert_raises(KeyError) { Config.from_yaml(YAML.dump(broken)) }
      assert_equal "configuration value is expected to be an array: scrapers", err.message
    end

    def test_missing_scraper_source
      broken = YAML.load(EXAMPLE)
      broken["scrapers"][0].delete("source")

      err = assert_raises(KeyError) { Config.from_yaml(YAML.dump(broken)) }
      assert_equal "configuration value not found: scrapers.0.source", err.message
    end

    def test_load_from_file
      filename = File.join(tmpdir, "test.yml")
      File.write(filename, EXAMPLE)

      assert_equal Config.from_yaml(EXAMPLE), Config.from_file(filename)
    end
  end
end
