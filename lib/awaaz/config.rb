# frozen_string_literal: true

##
# The Awaaz module serves as the top-level namespace for all components
# of the Awaaz gem, which provides audio decoding, resampling, and analysis tools.
#
module Awaaz
  ##
  # The Config class handles detection and configuration of available audio decoders
  # for the Awaaz gem. It checks the system for supported decoder binaries
  # (mpg123, ffmpeg, sox) and provides query helpers to check their availability.
  #
  # @example Check if `ffmpeg` is available
  #   Awaaz.config.ffmpeg? # => true or false
  #
  class Config
    ##
    # Creates a new configuration instance and detects available decoders.
    #
    def initialize
      @available_decoders = detect_decoders
    end

    ##
    # Checks if a given decoder is available on the system.
    #
    # @param name [Symbol, String] The name of the decoder (e.g., `:mpg123`, `"ffmpeg"`).
    # @return [Boolean] `true` if the decoder is available, otherwise `false`.
    #
    def decoder?(name)
      @available_decoders.include?(name.to_sym)
    end

    ##
    # Checks if mpg123 is available.
    #
    # @return [Boolean] `true` if mpg123 is installed, otherwise `false`.
    #
    def mpg123?
      decoder?(:mpg123)
    end

    ##
    # Checks if ffmpeg is available.
    #
    # @return [Boolean] `true` if ffmpeg is installed, otherwise `false`.
    #
    def ffmpeg?
      decoder?(:ffmpeg)
    end

    ##
    # Checks if sox is available.
    #
    # @return [Boolean] `true` if sox is installed, otherwise `false`.
    #
    def sox?
      decoder?(:sox)
    end

    ##
    # Lists all potential decoders that Awaaz can work with.
    #
    # @return [Array<Symbol>] An array of decoder names (`:mpg123`, `:ffmpeg`, `:sox`).
    #
    def potential_decoders
      %i[mpg123 ffmpeg sox]
    end

    ##
    # Checks if no decoders are available on the system.
    #
    # @return [Boolean] `true` if no decoders were detected, otherwise `false`.
    #
    def no_decoders?
      @available_decoders.nil? || @available_decoders.empty?
    end

    private

    ##
    # Detects which decoders are available by checking system binaries.
    #
    # @return [Array<Symbol>] An array of detected decoder names.
    #
    def detect_decoders
      decoders = []
      decoders << :mpg123 if system("which mpg123 > /dev/null 2>&1")
      decoders << :ffmpeg if system("which ffmpeg > /dev/null 2>&1")
      decoders << :sox    if system("which sox > /dev/null 2>&1")
      decoders
    end
  end

  class << self
    ##
    # Returns the current configuration object.
    #
    # @return [Awaaz::Config] The configuration instance.
    #
    def config
      @config ||= Config.new
    end

    ##
    # Yields the current configuration object for modifications.
    #
    # @yieldparam config [Awaaz::Config] The configuration instance.
    #
    def configure
      yield(config)
    end

    ##
    # Lists all potential decoders that Awaaz can work with.
    #
    # @return [Array<Symbol>] An array of decoder names.
    #
    def potential_decoders
      config.potential_decoders
    end
  end
end
