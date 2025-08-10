# frozen_string_literal: true

module Awaaz
  module Decoders
    class Mp3Decoder < BaseDecoder
      include Utils::ViaShell

      set_available_options

      def load
        validate_file_extension ".mp3"
        shell_load sox_options: { raw: true }
      end
    end
  end
end
