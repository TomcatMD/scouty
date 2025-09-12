# frozen_string_literal: true

module Scouty
  Config = Data.define(:webcache, :registry, :scrapers, :lm_studio, :notifier, :profile)

  ConfigWebcache = Data.define(:dir)
  ConfigRegistry = Data.define(:file)
  ConfigScrapper = Data.define(:source, :params)
  ConfigLMStudio = Data.define(:url, :model)
  ConfigNotifier = Data.define(:suppressed)

  class << Config
    def from_file(file)
      from_yaml(File.read(file))
    end

    def from_yaml(string)
      data = YAML.load(string)

      new(
        webcache: read_webcache_config(data),
        registry: read_registry_config(data),
        scrapers: read_scrapers_config(data),
        lm_studio: read_lm_studio_config(data),
        notifier: read_notifier_config(data),
        profile: read_profile_config(data)
      )
    end

    private

    def read_webcache_config(data)
      ConfigWebcache.new(dir: read_config(data, "webcache", "dir"))
    end

    def read_registry_config(data)
      ConfigRegistry.new(file: read_config(data, "registry", "file"))
    end

    def read_scrapers_config(data)
      value = data["scrapers"]

      raise KeyError, "configuration value is expected to be an array: scrapers" unless value.is_a?(Array)

      (0...value.length).map do |i|
        ConfigScrapper.new(
          source: read_config(data, "scrapers", i, "source"),
          params: read_config(data, "scrapers", i).except("source")
        )
      end
    end

    def read_lm_studio_config(data)
      ConfigLMStudio.new(
        url: read_config(data, "lm_studio", "url"),
        model: read_config(data, "lm_studio", "model")
      )
    end

    def read_notifier_config(data)
      ConfigNotifier.new(
        suppressed: read_config(data, "notifier", "suppressed", default: false)
      )
    end

    def read_profile_config(data)
      read_config(data, "profile")
    end

    def read_config(data, *keys, **kvargs)
      keys.reduce(data) { |acc, k| acc.fetch(k) }
    rescue KeyError
      raise KeyError, "configuration value not found: #{keys.join(".")}" unless kvargs.key?(:default)

      kvargs[:default]
    end
  end
end
