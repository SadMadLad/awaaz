# frozen_string_literal: true

module Awaaz
  # Utilities for Awaaz
  module Utils
    class << self
      ##
      # Calculates the total number of frames for a given signal length, frame size, and hop length.
      #
      # @param signal_length [Integer] Number of samples in the signal.
      # @param frame_size [Integer] Size of each analysis frame (in samples).
      # @param hop_length [Integer] Step size between consecutive frames (in samples).
      #
      # @return [Integer] The total number of frames.
      #
      def total_frames(signal_length, frame_size, hop_length)
        ((signal_length - frame_size) / hop_length.to_f).ceil + 1
      end

      ##
      # Computes how many samples are needed to right-pad a signal so
      # that its length perfectly fits the given frame and hop size.
      #
      # @param signal_length [Integer] Number of samples in the signal.
      # @param frame_size [Integer] Size of each analysis frame (in samples).
      # @param hop_length [Integer] Step size between consecutive frames (in samples).
      #
      # @return [Integer] Number of padding samples required.
      #
      def pad_amount(signal_length, frame_size, hop_length)
        frames = total_frames(signal_length, frame_size, hop_length)
        padded_length = ((frames - 1) * hop_length) + frame_size
        padded_length - signal_length
      end

      ##
      # Pads an array with zeros (or a specified value) along a given axis.
      #
      # @param array [Numo::NArray] The input array (e.g., shape [channels, samples]).
      # @param pad_count [Integer] Number of padding elements to add.
      # @param axis [Integer] Axis along which to pad (default: 1 for time axis).
      # @param with [Numeric] Value to pad with (default: 0).
      #
      # @return [Numo::NArray] The padded array.
      #
      def pad_right(array, pad_count, axis: 1, with: 0)
        channels_count = array.shape.first
        padded_array = Numo::SFloat.new(channels_count, pad_count).fill(with)

        array.concatenate(padded_array, axis:)
      end

      ##
      # Builds a list of sample index ranges for each analysis frame.
      #
      # @param signal_length [Integer] Number of samples in the (possibly padded) signal.
      # @param frame_size [Integer] Size of each frame (in samples).
      # @param hop_length [Integer] Step size between consecutive frames (in samples).
      #
      # @return [Array<Range>] An array where each element is the sample index range for one frame.
      #
      def build_ranges(signal_length, frame_size, hop_length)
        ranges = []
        start = 0
        while start + frame_size <= signal_length
          ranges << (start...(start + frame_size))
          start += hop_length
        end
        ranges
      end

      ##
      # Pads the signal (if necessary) and returns the padded array along with frame index ranges.
      #
      # @param array [Numo::NArray] A 2D array where shape is [channels, samples].
      # @param frame_size [Integer] Size of each frame (in samples).
      # @param hop_length [Integer] Step size between consecutive frames (in samples).
      #
      # @raise [ArgumentError] If hop length is less than 1.
      #
      # @return [Array<(Numo::NArray, Array<Range>)>]
      #   - padded signal array
      #   - array of frame index ranges
      #
      def frame_ranges(array, frame_size: 2048, hop_length: 512)
        raise ArgumentError, "Hop Length can't be less than 1" if hop_length < 1

        amount = pad_amount(array.shape[1], frame_size, hop_length)
        array = pad_right(array, amount) if amount.positive?

        [array, build_ranges(array.shape[1], frame_size, hop_length)]
      end

      ##
      # Calculates the RMS (Root Mean Square) energy for each frame in the given audio.
      #
      # @param samples [Numo::NArray] A 2D array of shape [channels, samples].
      # @param frame_size [Integer] Size of each analysis frame (in samples).
      # @param hop_length [Integer] Step size between consecutive frames (in samples).
      #
      # @return [Numo::SFloat] A 2D array of RMS values with shape [channels, frames].
      #
      def rms(samples, frame_size: 2048, hop_length: 512)
        samples, frame_groups = frame_ranges(samples, frame_size:, hop_length:)

        means = Numo::SFloat.zeros(samples.shape[0], frame_groups.length)
        frame_groups.each_with_index do |frame_range, idx|
          frame = samples[true, frame_range]
          means[true, idx] = Numo::NMath.sqrt((frame**2).mean(1))
        end
        means
      end

      ##
      # Calculates the overall RMS for an entire signal without framing.
      #
      # @param samples [Numo::NArray] A 2D or 1D array of samples.
      #
      # @return [Float] RMS value for the entire signal.
      #
      def rms_overall(samples)
        Math.sqrt((samples**2).mean)
      end

      # Calculates the zero-crossing rate (ZCR) of an audio signal frame-by-frame.
      #
      # The zero-crossing rate is the proportion of consecutive samples in a frame
      # where the signal changes sign (positive to negative or vice versa).
      # It is often used as a simple feature in speech/music analysis.
      #
      # @param samples [Numo::NArray] 2D array of audio samples.
      #   Shape: [n_channels, n_samples].
      # @param frame_size [Integer] Size of each analysis frame in samples. Default: 2048.
      # @param hop_length [Integer] Step size between successive frames in samples. Default: 512.
      # @return [Numo::SFloat] 2D array of zero-crossing rates per frame for each channel.
      #   Shape: [n_channels, n_frames].
      #
      # @example
      #   # Stereo signal: 2 channels, 44100 samples
      #   zcr_values = zcr(samples, frame_size: 2048, hop_length: 512)
      #   puts zcr_values.shape  # => [2, n_frames]
      #
      # rubocop:disable Style/NumericPredicate
      def zcr(samples, frame_size: 2048, hop_length: 512)
        framed_samples, frame_groups = frame_ranges(samples, frame_size:, hop_length:)

        n_channels = framed_samples.shape[0]
        zcrs = Numo::SFloat.zeros(n_channels, frame_groups.length)

        frame_groups.each_with_index do |frame_range, idx|
          zcrs[true, idx] = zcr_for_frame(framed_samples[true, frame_range], frame_size)
        end

        zcrs
      end

      # Calculates the zero-crossing rate for a single frame of audio.
      #
      # @param frame [Numo::NArray] 2D array containing audio samples for a single frame.
      #   Shape: [n_channels, frame_size].
      # @param frame_size [Integer] Number of samples in the frame.
      # @return [Numo::SFloat] 1D array of zero-crossing rates for each channel in the frame.
      #   Shape: [n_channels].
      #
      # @example
      #   frame = samples[true, 0...2048]
      #   single_frame_zcr = zcr_for_frame(frame, 2048)
      #   puts single_frame_zcr  # => Numo::SFloat[0.15, 0.12]
      def zcr_for_frame(frame, frame_size)
        first_part = frame[true, 0...-1]
        second_part = frame[true, 1..-1]
        products = first_part * second_part

        sign_changes = products < 0
        counts = sign_changes.count_true(axis: 1)

        counts / frame_size.to_f
      end
      # rubocop:enable Style/NumericPredicate

      # Calculates the overall zero-crossing rate (ZCR) of an entire audio signal.
      #
      # @param samples [Numo::NArray] 2D array of audio samples.
      #   Shape: [n_channels, n_samples].
      # @return [Numo::SFloat] 1D array containing the overall ZCR for each channel.
      #   Shape: [n_channels].
      #
      # @example
      #   # Stereo signal: 2 channels, 44100 samples
      #   overall_zcr = zcr_overall(samples)
      #   puts overall_zcr.shape  # => [2]
      #
      # rubocop:disable Style/NumericPredicate
      #
      def zcr_overall(samples)
        ((samples[true, 0...-1] * samples[true, 1..-1]) < 0).count_true(axis: 1) / samples.shape[1].to_f
      end
      #
      # rubocop:enable Style/NumericPredicate
    end
  end
end
