# frozen_string_literal: true

module Awaaz
  module Utils
    ##
    # Resample utilities for audio data represented as Numo::NArray.
    # Wraps the `libsamplerate` bindings provided by {Extensions::Samplerate}.
    #
    # @note This module is intended for internal use, but `read_and_resample`
    #   is public for advanced users who need manual resampling.
    module Resample
      class << self
        ##
        # Resamples a Numo::SFloat array of audio samples from one sample rate to another.
        #
        # @param input_samples [Numo::SFloat] The audio samples to resample.
        # @param input_rate [Integer] The original sample rate (Hz).
        # @param output_rate [Integer] The desired sample rate (Hz).
        # @param sampling_option [Symbol, Integer] The resampling quality option.
        #   Can be one of:
        #     * `:sinc_best_quality` (0)
        #     * `:sinc_medium_quality` (1)
        #     * `:sinc_fastest` (2)
        #     * `:zero_order_hold` (3)
        #     * `:linear` (4)
        #
        # @return [Numo::SFloat] The resampled audio data.
        #
        # @raise [ArgumentError] If inputs are invalid or ratio is out of range.
        # @raise [Awaaz::ResampleError] If `libsamplerate` returns an error.
        #
        # @example Resample 44.1kHz mono audio to 48kHz
        #   samples = Numo::SFloat.new(44100).rand
        #   new_samples = Awaaz::Utils::Resample.read_and_resample(samples, 44100, 48000)
        def read_and_resample(input_samples, input_rate, output_rate, sampling_option: :linear)
          validate_inputs(input_samples, input_rate, output_rate)

          ratio = calculate_ratio(input_rate, output_rate)
          input_ptr, output_ptr, input_frames, output_frames = prepare_memory(input_samples, ratio)

          data = build_src_data(input_ptr, output_ptr, input_frames, output_frames, ratio)
          perform_resampling(data, sampling_option)

          convert_to_numo(output_ptr, data[:output_frames_gen])
        end

        private

        ##
        # Validates that the provided inputs are of the correct type and configuration.
        #
        # @param samples [Numo::NArray] The input samples.
        # @param input_rate [Integer]
        # @param output_rate [Integer]
        #
        # @raise [ArgumentError] If samples are not a Numo::SFloat array.
        def validate_inputs(samples, input_rate, output_rate)
          return if input_rate != output_rate && samples.is_a?(Numo::NArray)

          raise ArgumentError, "Input must be a Numo::SFloat array" unless samples.is_a?(Numo::NArray)
        end

        ##
        # Calculates and validates the resampling ratio.
        #
        # @param input_rate [Integer]
        # @param output_rate [Integer]
        #
        # @return [Float] The ratio of output_rate to input_rate.
        # @raise [ArgumentError] If ratio is outside the allowed range.
        def calculate_ratio(input_rate, output_rate)
          ratio = output_rate / input_rate.to_f
          raise ArgumentError, "Bad ratio" if ratio < 1.0 / 256 || ratio > 256

          ratio
        end

        ##
        # Allocates and prepares FFI memory for the input and output buffers.
        #
        # @param input_samples [Numo::NArray]
        # @param ratio [Float] The resampling ratio.
        #
        # @return [Array<FFI::MemoryPointer, FFI::MemoryPointer, Integer, Integer>]
        def prepare_memory(input_samples, ratio)
          input_frames = input_samples.size
          output_frames = (input_frames * ratio).to_i

          input_ptr = FFI::MemoryPointer.new(:float, input_frames)
          input_ptr.write_bytes(input_samples.to_string)

          output_ptr = FFI::MemoryPointer.new(:float, output_frames)

          [input_ptr, output_ptr, input_frames, output_frames]
        end

        ##
        # Builds the {Extensions::Samplerate::SRC_DATA} struct for `libsamplerate`.
        #
        # @param input_ptr [FFI::MemoryPointer]
        # @param output_ptr [FFI::MemoryPointer]
        # @param input_frames [Integer]
        # @param output_frames [Integer]
        # @param ratio [Float]
        #
        # @return [Extensions::Samplerate::SRC_DATA]
        def build_src_data(input_ptr, output_ptr, input_frames, output_frames, ratio)
          Extensions::Samplerate::SRC_DATA.new.tap do |data|
            data[:data_in] = input_ptr
            data[:data_out] = output_ptr
            data[:input_frames] = input_frames
            data[:output_frames] = output_frames
            data[:end_of_input] = 1
            data[:src_ratio] = ratio
          end
        end

        ##
        # Performs the resampling using `libsamplerate`.
        #
        # @param data [Extensions::Samplerate::SRC_DATA]
        # @param sampling_option [Symbol, Integer]
        #
        # @raise [Awaaz::ResampleError] If resampling fails.
        def perform_resampling(data, sampling_option)
          err = Extensions::Samplerate.src_simple(data, Extensions::Samplerate.resample_option(sampling_option), 1)
          raise Awaaz::ResampleError, "Resampling failed: #{Extensions::Samplerate.src_strerror(err)}" if err != 0
        end

        ##
        # Converts the output FFI pointer back into a Numo::SFloat array.
        #
        # @param output_ptr [FFI::MemoryPointer]
        # @param size [Integer] Number of frames generated.
        #
        # @return [Numo::SFloat]
        def convert_to_numo(output_ptr, size)
          Numo::SFloat.cast(output_ptr.read_array_of_float(size))
        end
      end
    end
  end
end
