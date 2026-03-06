# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestOllamaClient < Minitest::Test
    TEST_URL = "http://localhost:11434"
    TEST_MODEL = "gpt-oss:20b"

    def client
      @client ||= OllamaClient.new(url: TEST_URL, model: TEST_MODEL)
    end

    def test_ask_basic_usage
      reply =
        VCR.use_cassette("scouty/test_ollama_client/test_ask_basic_usage") do
          client.ask("Reply 'Hello, World!'")
        end

      assert_equal "Hello, World!", reply
    end

    def test_ask_with_instructions
      reply =
        VCR.use_cassette("scouty/test_ollama_client/test_ask_with_instructions") do
          client.ask("Alex", instructions: "Reply with 'Hello, <PROVIDED NAME>!'")
        end

      assert_equal "Hello, Alex!", reply
    end

    def test_ask_with_temperature
      reply =
        VCR.use_cassette("scouty/test_ollama_client/test_ask_with_temperature") do
          client.ask("Say something!", temperature: 1.23)
        end

      assert_equal "Did you know that the average person walks about 100,000 " \
                   "miles in their lifetime—roughly two and a half times " \
                   "around the world? 🚶‍♂️🌍 Every step tells a story, even the " \
                   "ones we barely notice. How would you rewrite your own " \
                   "\"walking story\" if you could choose the destination?",
                   reply
    end
  end
end
