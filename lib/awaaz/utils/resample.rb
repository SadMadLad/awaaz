# frozen_string_literal: true

module Awaaz
  module Utils
    module Resample
      class << self
        def read_and_resample_numo(input_samples, input_rate, output_rate, sampling_option: :linear)
          return input_samples if input_rate == output_rate
          raise ArgumentError, "Input must be a Numo::SFloat array" unless input_samples.is_a?(Numo::NArray)

          ratio = output_rate / input_rate.to_f
          raise ArgumentError, "Bad ratio" if ratio < 1.0 / 256 || ratio > 256

          input_frames = input_samples.size
          output_frames = (input_frames * ratio).to_i
          raw_input_data = input_samples.to_string

          input_ptr = FFI::MemoryPointer.new(:float, input_frames)
          input_ptr.write_bytes(raw_input_data)

          output_ptr = FFI::MemoryPointer.new(:float, output_frames)

          data = Extensions::Samplerate::SRC_DATA.new
          data[:data_in] = input_ptr
          data[:data_out] = output_ptr
          data[:input_frames] = input_frames
          data[:output_frames] = output_frames
          data[:end_of_input] = 1
          data[:src_ratio] = ratio

          err = Extensions::Samplerate.src_simple(data, Extensions::Samplerate.resample_option(sampling_option), 1)
          raise Awaaz::ResampleError, "Resampling failed: #{Extensions::Samplerate.src_strerror(err)}" if err != 0

          resampled_size = data[:output_frames_gen]
          Numo::SFloat.cast(output_ptr.read_array_of_float(resampled_size))
        end
      end
    end
  end
end
