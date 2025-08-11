# frozen_string_literal: true

# This file loads all available decoders for the Awaaz gem.
# It ensures that the base decoder and all specific decoder
# implementations (e.g., MP3, WAV) are required and ready
# for use under the {Awaaz::Decoders} namespace.
#
# @example Accessing a decoder
#   Awaaz::Decoders::Mp3Decoder.new.load
#
# @see Awaaz::Decoders::BaseDecoder
# @see Awaaz::Decoders::Mp3Decoder
# @see Awaaz::Decoders::WavefileDecoder
#

require_relative "base_decoder"
require_relative "mp3_decoder"
require_relative "wavefile_decoder"

module Awaaz
  # Namespace for all audio decoder implementations.
  #
  # Each decoder is responsible for loading and processing
  # a specific audio format into a format usable by the Awaaz system.
  #
  # @since 0.1.0
  module Decoders
  end
end
