# frozen_string_literal: true

module Lyrebird
  class Options
    def initialize(values = {})
      @values = values.transform_keys(&:to_sym)
    end

    def to_h
      @values
    end

    def [](key)
      @values[key.to_sym]
    end

    def []=(key, value)
      @values[key.to_sym] = value
    end

    private

    def method_missing(name, *args)
      key = name.to_s

      if key.end_with?("=")
        @values[key.chomp("=").to_sym] = args.first
      elsif @values.key?(name)
        @values[name]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      name.to_s.end_with?("=") || @values.key?(name) || super
    end
  end
end
