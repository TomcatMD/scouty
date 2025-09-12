# frozen_string_literal: true

module Scouty
  class LMStudioClient
    DEFAULT_URL   = "http://127.0.0.1:1234"
    DEFAULT_MODEL = "openai/gpt-oss-20b"

    attr_reader :url, :model, :conn

    def initialize(url: DEFAULT_URL, model: DEFAULT_MODEL)
      @url = url
      @model = model
      @conn = init_faraday_connection
    end

    def ask(message, instructions: nil, temperature: nil)
      res = conn.post(
        "/v1/chat/completions",
        build_completion_request_body(message:, instructions:, temperature:)
      )

      extract_completion_reply(res.body)
    end

    private

    def init_faraday_connection
      Faraday.new(url: url) do |builder|
        builder.request  :json
        builder.response :json
        builder.response :raise_error
      end
    end

    def build_completion_request_body(message:, instructions:, temperature:)
      body = {
        "model" => model,
        "n" => 1,
        "messages" => build_completion_request_messages(message:, instructions:)
      }
      body["temperature"] = temperature unless temperature.nil?
      body
    end

    def build_completion_request_messages(message:, instructions:)
      arr = []
      arr << { "role" => "developer", "content" => instructions } unless instructions.nil?
      arr << { "role" => "user", "content" => message }
      arr
    end

    def extract_completion_reply(body)
      body
        .fetch("choices")
        .fetch(0)
        .fetch("message")
        .fetch("content")
    end
  end
end
