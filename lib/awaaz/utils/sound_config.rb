# frozen_string_literal: true

module Awaaz
  module Utils
    ##
    # SoundConfig holds and validates configuration options used for audio processing.
    #
    # It ensures that only valid options are passed in and provides convenience
    # accessors for common audio processing settings such as sample rate, channel count,
    # amplification factor, and decoder preferences.
    #
    # @example Creating a SoundConfig with valid options
    #   valid_keys = [:sample_rate, :mono, :amplification_factor, :decoder]
    #   config = Awaaz::Utils::SoundConfig.new(valid_keys, sample_rate: 44100, mono: true)
    #
    class SoundConfig
      ##
      # Initializes a new SoundConfig instance.
      #
      # @param valid_options [Array<Symbol,String>] The list of allowed option keys.
      # @param options [Hash] The configuration options to store.
      # @option options [Integer] :sample_rate The audio sample rate in Hz.
      # @option options [Boolean] :mono Whether to process audio in mono (true) or stereo (false).
      # @option options [Boolean] :soundread Whether to use soundread for processing.
      # @option options [Integer] :amplification_factor The amplification factor (default: 32768).
      # @option options [Symbol,String] :decoder The preferred audio decoder.
      #
      # @raise [ArgumentError] If any provided option key is not in +valid_options+.
      #
      def initialize(valid_options, **options)
        @options = options
        @valid_options = valid_options

        prepare
      end

      ##
      # The sample rate for audio processing.
      #
      # @return [Integer] The sample rate in Hz (default: 22050).
      #
      def sample_rate
        from_options(:sample_rate) || 22_050
      end

      ##
      # Whether to process audio in mono.
      #
      # @return [Boolean] +true+ if mono, otherwise +false+.
      #
      def mono
        from_options(:mono) || false
      end

      ##
      # Resampling option
      #
      # @return [Symbol] default :linear
      #
      def resampling_option
        from_options(:resampling_option) || :linear
      end

      ##
      # Convenience method to check if audio is mono.
      #
      # @return [Boolean]
      #
      def mono?
        mono
      end

      ##
      # Convenience method to check if audio is stereo.
      #
      # @return [Boolean]
      #
      def stereo?
        !mono?
      end

      ##
      # Whether to use soundread for audio processing.
      #
      # @return [Boolean]
      #
      def soundread?
        from_options(:soundread) == true
      end

      ##
      # The number of audio channels.
      #
      # @return [Integer] 1 for mono, 2 for stereo.
      #
      def num_channels
        mono? ? 1 : 2
      end

      ##
      # The amplification factor for audio processing.
      #
      # @return [Integer] Defaults to 32768.
      #
      def amplification_factor
        (from_options(:amplification_factor) || 32_768).to_i
      end

      ##
      # The preferred audio decoder.
      #
      # @return [Symbol, nil] The decoder symbol if set, otherwise +nil+.
      #
      def decoder_option
        from_options(:decoder)&.to_sym
      end

      private

      ##
      # Fetches a value from @options using either symbol or string key.
      #
      # @param key [Symbol,String] The key to look up.
      # @return [Object, nil] The value if present, otherwise +nil+.
      #
      def from_options(key)
        @options[key.to_s] || @options[key.to_sym]
      end

      ##
      # Validates that all provided options are in the allowed list.
      #
      # @raise [ArgumentError] If any provided key is invalid.
      #
      def prepare
        @options.each_key do |key|
          next if @valid_options.include?(key.to_sym) || @valid_options.include?(key.to_s)

          raise ArgumentError, "Invalid key passed: #{key}. Possible keys: #{@valid_options.join(",")}"
        end
      end
    end
  end
end
