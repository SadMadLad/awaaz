# frozen_string_literal: true

module Awaaz
  module Utils
    class SoundConfig
      def initialize(valid_options, **options)
        @options = options
        @valid_options = valid_options

        prepare
      end

      # Possible options when processing audio
      def sample_rate
        from_options(:sample_rate) || 22_050
      end

      def mono
        from_options(:mono) || false
      end

      def mono?
        mono
      end

      def stereo?
        !mono?
      end

      def soundread?
        from_options(:soundread) == true
      end

      def num_channels
        mono? ? 1 : 2
      end

      def amplification_factor
        (from_options(:amplification_factor) || 32_768).to_i
      end

      def decoder_option
        from_options(:decoder)&.to_sym
      end

      private

      def from_options(key)
        @options[key.to_s] || @options[key.to_sym]
      end

      def prepare
        @options.each_key do |key|
          next if @valid_options.include?(key.to_sym) || @valid_options.include?(key.to_s)

          raise ArgumentError, "Invalid key passed: #{key}. Possible keys: #{@valid_options.join(",")}"
        end
      end
    end
  end
end
