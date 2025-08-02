# frozen_string_literal: true

require_relative "base_decoder"
require_relative "via_shell"

module Awaaz
  module Decoders
    class Mp3Decoder < BaseDecoder
      include ViaShell

      set_available_options

      def load
        validate_options
        validate_file_extension ".mp3"
        shell_load sox_options: { raw: true }
      end
    end
  end
end
