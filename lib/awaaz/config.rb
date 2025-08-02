# frozen_string_literal: true

module Awaaz
  class Config
    def initialize
      @available_decoders = detect_decoders
    end

    def decoder?(name)
      @available_decoders.include?(name.to_sym)
    end

    def mpg123?
      decoder?(:mpg123)
    end

    def ffmpeg?
      decoder?(:ffmpeg)
    end

    def sox?
      decoder?(:sox)
    end

    def potential_decoders
      %i[mpg123 ffmpeg sox]
    end

    def no_decoders?
      @available_decoders.nil? || @available_decoders.empty?
    end

    private
      def detect_decoders
        decoders = []
        decoders << :mpg123 if system("which mpg123 > /dev/null 2>&1")
        decoders << :ffmpeg if system("which ffmpeg > /dev/null 2>&1")
        decoders << :sox    if system("which sox > /dev/null 2>&1")

        decoders
      end
  end

  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end

    def potential_decoders
      config.potential_decorders
    end
  end
end
