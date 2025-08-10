# frozen_string_literal: true

module Awaaz
  module Decoders
    class WavefileDecoder < BaseDecoder
      include Utils::ViaShell

      set_available_options default_available_options + [:soundread]

      def load
        validate_options
        validate_file_extension ".wav"

        return shell_load sox_options: { raw: true } unless no_decoders? || soundread?
        
        soundread
      end

      private
        def soundread?
          from_options(:soundread) == true
        end

        def soundread
          samples, channels, output_rate = Utils::Soundread.new(@filename).read
          
          Utils::Samples.new(output_rate, channels, samples)
        end
    end
  end
end
