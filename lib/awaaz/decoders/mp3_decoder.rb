# frozen_string_literal: true

module Awaaz
  module Decoders
    ##
    # The Mp3Decoder class provides decoding functionality for `.mp3` files
    # within the Awaaz gem.
    #
    # It inherits from {BaseDecoder} and uses the {Utils::ViaShell} mixin
    # to perform decoding via shell commands (e.g., Sox).
    #
    # @example Basic usage
    #   decoder = Awaaz::Decoders::Mp3Decoder.new(file_path: "song.mp3")
    #   samples = decoder.load
    #
    # @see BaseDecoder
    # @see Utils::ViaShell
    #
    class Mp3Decoder < BaseDecoder
      include Utils::ViaShell

      # Sets available options for this decoder (defined in BaseDecoder).
      set_available_options

      ##
      # Loads and processes an MP3 file.
      #
      # This method:
      # 1. Validates that the file has a `.mp3` extension.
      # 2. Uses {Utils::ViaShell#shell_load} to load raw audio data.
      # 3. Passes the loaded data to {BaseDecoder#process} for further handling.
      #
      # @raise [ArgumentError]
      #   If the file does not have a `.mp3` extension.
      #
      # @return [Object]
      #   The processed audio data (return type depends on BaseDecoder#process).
      #
      def load
        validate_file_extension ".mp3"
        process(*shell_load(sox_options: { raw: true }))
      end
    end
  end
end
