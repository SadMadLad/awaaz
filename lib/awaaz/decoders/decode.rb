# frozen_string_literal: true

require "filemagic"

# The Awaaz gem provides audio decoding utilities and related tools for working
# with various audio formats. It uses FFI bindings and Numo::NArray for numerical
# processing and includes multiple decoders, utilities, and configuration options.
module Awaaz
  # Mapping of MIME types to their respective decoder classes.
  DECODER_MAP = {
    "audio/wav" => Decoders::WavefileDecoder,
    "audio/x-wav" => Decoders::WavefileDecoder,
    "audio/wave" => Decoders::WavefileDecoder,
    "audio/vnd.wave" => Decoders::WavefileDecoder,
    "audio/mpeg" => Decoders::Mp3Decoder,
    "audio/mp3" => Decoders::Mp3Decoder,
    "audio/x-mpeg" => Decoders::Mp3Decoder,
    "audio/x-mp3" => Decoders::Mp3Decoder
  }.freeze

  class << self
    # Loads an audio file and processes it using the appropriate decoder
    # based on the file's MIME type.
    #
    # @param filename [String] the path to the audio file
    # @raise [ArgumentError] if the MIME type is not supported
    # @return [Object] the result of decoding, as returned by the decoder class
    def load(filename)
      fm = FileMagic.new(FileMagic::MAGIC_MIME_TYPE)
      mime_type = fm.file(filename)

      unless DECODER_MAP.key?(mime_type)
        raise ArgumentError,
              "Cannot load the file. Available mime types: #{DECODER_MAP.keys.join(", ")}"
      end

      decoding_class = DECODER_MAP[mime_type]
      decoding_class.load(filename)
    end
  end
end
