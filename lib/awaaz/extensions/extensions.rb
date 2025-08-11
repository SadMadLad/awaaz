# frozen_string_literal: true

require_relative "soundfile"
require_relative "samplerate"

module Awaaz
  # The Extensions namespace contains low-level bindings and helper classes
  # for audio file reading and resampling.
  #
  # @note These extensions are generally implemented using {FFI}
  #   and provide direct access to C libraries like `libsndfile` and `libsamplerate`.
  #
  # @see Extensions::Soundfile
  # @see Extensions::Samplerate
  module Extensions
  end
end
