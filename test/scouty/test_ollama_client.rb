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

      assert_equal "Hey there! I’m all ears (and circuits) – what’s on your " \
                   "mind today? If you need a quick fact, a joke, or just a " \
                   "random tidbit, I’ve got you covered. 🎉",
                   reply
    end
  end
end
