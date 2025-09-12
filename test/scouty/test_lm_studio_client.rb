# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestLMStudioClient < Minitest::Test
    TEST_URL = "http://127.0.0.1:1234"
    TEST_MODEL = "openai/gpt-oss-20b"

    def client
      @client ||= LMStudioClient.new(url: TEST_URL, model: TEST_MODEL)
    end

    def test_ask_basic_usage
      reply =
        VCR.use_cassette("scouty/test_lm_studio_client/test_ask_basic_usage") do
          client.ask("Reply 'Hello, World!'")
        end

      assert_equal "Hello, World!", reply
    end

    def test_ask_with_instructions
      reply =
        VCR.use_cassette("scouty/test_lm_studio_client/test_ask_with_instructions") do
          client.ask("Alex", instructions: "Reply with 'Hello, <PROVIDED NAME>!'")
        end

      assert_equal "Hello, Alex!", reply
    end

    def test_ask_with_temperature
      reply =
        VCR.use_cassette("scouty/test_lm_studio_client/test_ask_with_temperature") do
          client.ask("Say something!", temperature: 1.23)
        end

      assert_equal "Hello there! How’s your day going?", reply
    end
  end
end
