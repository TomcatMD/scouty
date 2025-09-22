# frozen_string_literal: true

module Scouty
  class ReportServer
    attr_reader :registry, :notifier

    def initialize(registry:, notifier:)
      @registry = registry
      @notifier = notifier
    end

    def serve
      report = registry.generate_report
      notifier.notify("report.generated", report:)
    end
  end
end
