# frozen_string_literal: true

module Awaaz
  ##
  # The Extensions module is a namespace for FFI-based bindings to external libraries.
  module Extensions
    ##
    # The Samplerate module provides Ruby bindings to the `libsamplerate` C library
    # using the FFI (Foreign Function Interface).
    #
    # This module enables high-quality audio resampling directly from Ruby.
    #
    # @see https://libsndfile.github.io/libsamplerate/api.html Official libsamplerate API documentation
    module Samplerate
      extend FFI::Library

      # Load the libsamplerate shared library
      ffi_lib "samplerate"

      # rubocop:disable Naming/ClassAndModuleCamelCase

      ##
      # Structure representing the parameters for a sample rate conversion operation.
      #
      # Mirrors the C struct `SRC_DATA` from libsamplerate.
      #
      # @!attribute [rw] data_in
      #   @return [FFI::Pointer] Pointer to the input audio buffer.
      # @!attribute [rw] data_out
      #   @return [FFI::Pointer] Pointer to the output audio buffer.
      # @!attribute [rw] input_frames
      #   @return [Integer] Number of input frames.
      # @!attribute [rw] output_frames
      #   @return [Integer] Number of output frames allocated.
      # @!attribute [rw] input_frames_used
      #   @return [Integer] Number of input frames actually used.
      # @!attribute [rw] output_frames_gen
      #   @return [Integer] Number of output frames generated.
      # @!attribute [rw] end_of_input
      #   @return [Integer] Flag (0 or 1) indicating whether this is the last block of input data.
      # @!attribute [rw] src_ratio
      #   @return [Float] Conversion ratio (output_sample_rate / input_sample_rate).
      class SRC_DATA < FFI::Struct
        layout :data_in, :pointer,
               :data_out, :pointer,
               :input_frames,      :long,
               :output_frames,     :long,
               :input_frames_used, :long,
               :output_frames_gen, :long,
               :end_of_input,      :int,
               :src_ratio,         :double
      end

      # rubocop:enable Naming/ClassAndModuleCamelCase

      ##
      # Performs a simple sample rate conversion.
      #
      attach_function :src_simple, [SRC_DATA.by_ref, :int, :int], :int

      ##
      # Converts an error code to a human-readable error message.
      #
      # @return [String] Human-readable error message.
      attach_function :src_strerror, [:int], :string

      # --- Converter type constants ---

      # Best quality sinc-based sample rate converter.
      SRC_SINC_BEST_QUALITY = 0

      # Medium quality sinc-based converter.
      SRC_SINC_MEDIUM_QUALITY = 1

      # Fastest sinc-based converter (lower quality).
      SRC_SINC_FASTEST = 2

      # Zero-order hold converter (lowest quality, fastest).
      SRC_ZERO_ORDER_HOLD = 3

      # Linear interpolation converter (low quality, very fast).
      SRC_LINEAR = 4

      class << self
        ##
        # Maps a symbolic or numeric option to a libsamplerate converter type constant.
        #
        # @param option [Integer, Symbol] Converter type, either as an integer constant
        #   or a symbol (:sinc_best_quality, :linear, etc.).
        # @return [Integer] The corresponding converter type constant.
        # @raise [ArgumentError] If the option is not recognized.
        #
        # @example Using symbols
        #   Extensions::Samplerate.resample_option(:sinc_best_quality)
        #   # => 0
        #
        # @example Using integers
        #   Extensions::Samplerate.resample_option(:linear)
        #   # => 4
        def resample_option(option)
          case option
          when 0, :sinc_best_quality then SRC_SINC_BEST_QUALITY
          when 1, :sinc_medium_quality then SRC_SINC_MEDIUM_QUALITY
          when 2, :sinc_fastest then SRC_SINC_FASTEST
          when 3, :zero_order_hold then SRC_ZERO_ORDER_HOLD
          when 4, :linear then SRC_LINEAR
          else
            raise ArgumentError, "Not found"
          end
        end
      end
    end
  end
end
