# frozen_string_literal: true

module Awaaz
  module Decoders
    class WavefileDecoder < BaseDecoder
      include Utils::ViaShell

      set_available_options default_available_options + [:soundread]

      def load
        validate_file_extension ".wav"

        return shell_load sox_options: { raw: true } unless no_decoders? || soundread?
        
        soundread
      end

      private
        def soundread? = @options.soundread?

        def soundread
          samples, channels, output_rate = Utils::Soundread.new(@filename).read
          
          Utils::Samples.new(output_rate, channels, samples, mono:)
        end
    end
  end
end
