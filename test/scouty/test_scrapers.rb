# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestScrapers < Minitest::Test
    def webcache
      @webcache ||= mock
    end

    def test_from_configs
      configs = [
        mock(source: "list", params: { "list" => ["https://example.com/job"] }),
        mock(source: "justjoin.it", params: { "categories" => ["ruby"] }),
        mock(source: "nofluffjobs.com", params: { "categories" => ["backend"] }),
        mock(source: "remoteok.com", params: {})
      ]

      result = Scrapers.from_configs(configs, webcache:)

      assert_instance_of Scrapers::StaticList, result[0]
      assert_equal ["https://example.com/job"], result[0].list

      assert_instance_of Scrapers::JustJoinIT, result[1]
      assert_equal ["ruby"], result[1].categories

      assert_instance_of Scrapers::NoFluffJobs, result[2]
      assert_equal ["backend"], result[2].categories

      assert_instance_of Scrapers::RemoteOK, result[3]
      assert_same webcache, result[3].webcache

      err =
        assert_raises(ArgumentError) do
          Scrapers.from_configs([mock(source: "unknown.com", params: {})], webcache:)
        end

      assert_equal "unknown source for scraping: unknown.com", err.message
    end

    def test_init_just_join_it_with_categories
      result = Scrapers.init("justjoin.it", webcache:, params: { "categories" => ["ruby"] })

      assert_instance_of Scrapers::JustJoinIT, result
      assert_equal ["ruby"], result.categories
    end

    def test_init_just_join_it_without_categories
      result = Scrapers.init("justjoin.it", webcache:)

      assert_instance_of Scrapers::JustJoinIT, result
      assert_nil result.categories
    end

    def test_init_no_fluff_jobs_with_categories
      result = Scrapers.init("nofluffjobs.com", webcache:, params: { "categories" => ["backend"] })

      assert_instance_of Scrapers::NoFluffJobs, result
      assert_equal ["backend"], result.categories
    end

    def test_init_no_fluff_jobs_without_categories
      result = Scrapers.init("nofluffjobs.com", webcache:, params: {})

      assert_instance_of Scrapers::NoFluffJobs, result
      assert_nil result.categories
    end

    def test_init_remote_ok
      result = Scrapers.init("remoteok.com", webcache:)

      assert_instance_of Scrapers::RemoteOK, result
      assert_same webcache, result.webcache
    end

    def test_init_static_list
      result = Scrapers.init("list", webcache:, params: { "list" => ["https://example.com/job"] })

      assert_instance_of Scrapers::StaticList, result
      assert_equal ["https://example.com/job"], result.list
    end

    def test_init_unknown_source
      err = assert_raises(ArgumentError) { Scrapers.init("unknown.com", webcache:) }
      assert_equal "unknown source for scraping: unknown.com", err.message
    end
  end
end
