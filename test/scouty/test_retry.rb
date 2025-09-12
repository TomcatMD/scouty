# frozen_string_literal: true

require "test_helper"

module Scouty
  class TestRetry < Minitest::Test
    class ExceptionExample < StandardError; end

    def test_success
      count = 0

      result =
        Retry.run(base_interval: 0) do
          count += 1
          raise ExceptionExample, "an error" if count < 2

          "some result on the third call"
        end

      assert_equal "some result on the third call", result
    end

    def test_failure
      count = 0

      err =
        assert_raises(ExceptionExample) do
          Retry.run(base_interval: 0) do
            count += 1
            raise ExceptionExample, "an error"
          end
        end

      assert_equal "an error", err.message
      assert_equal 5, count
    end
  end
end
