# frozen_string_literal: true

##
# The Awaaz module serves as the top-level namespace for all components
# of the Awaaz gem, which provides audio decoding, resampling, and analysis tools.
#
# This file defines the core exception classes used throughout the library.
#
# @see Awaaz::Config for configuration handling
# @see Awaaz::Decoders for decoder implementations
#
module Awaaz
  ##
  # Raised when no suitable audio decoder is found on the system.
  #
  # This error is typically raised when attempting to decode an audio file
  # but none of the configured or available decoders (e.g., `mpg123`, `ffmpeg`, `sox`)
  # are detected or usable.
  #
  # @example
  #   raise Awaaz::DecoderNotFound, "No decoders available"
  #
  class DecoderNotFound < ArgumentError; end

  ##
  # Raised when an error occurs during the resampling process.
  #
  # This error generally indicates an issue with the resampling library
  # or invalid audio data being passed for resampling.
  #
  # @example
  #   raise Awaaz::ResamplingError, "Invalid resampling ratio"
  #
  class ResamplingError < StandardError; end

  ##
  # Raised when the {https://github.com/beetbox/audioread audioread} backend
  # encounters an error while decoding audio files.
  #
  # This can happen when the file format is unsupported or if
  # the decoding process fails unexpectedly.
  #
  # @example
  #   raise Awaaz::AudioreadError, "Failed to read audio file"
  #
  class AudioreadError < StandardError; end
end
