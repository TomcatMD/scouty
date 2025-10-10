# frozen_string_literal: true

module Scouty
  class OllamaClient
    DEFAULT_URL   = "http://localhost:11434"
    DEFAULT_MODEL = "gpt-oss:20b"

    attr_reader :url, :model, :conn

    def initialize(url: DEFAULT_URL, model: DEFAULT_MODEL)
      @url = url
      @model = model
      @conn = init_faraday_connection
    end

    def ask(message, instructions: nil, temperature: nil)
      res = conn.post(
        "/api/generate",
        build_generate_request_body(message:, instructions:, temperature:)
      )

      extract_generate_response_body(res.body)
    end

    private

    def init_faraday_connection
      Faraday.new(url: url) do |builder|
        builder.request  :json
        builder.response :json
        builder.response :raise_error
      end
    end

    def build_generate_request_body(message:, instructions:, temperature:)
      body = {
        "model" => model,
        "system" => instructions,
        "prompt" => message,
        "stream" => false
      }

      body["options"] = { "temperature" => temperature } unless temperature.nil?

      body
    end

    def extract_generate_response_body(body)
      body.fetch("response")
    end
  end
end
