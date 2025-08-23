# frozen_string_literal: true

# Awaaz gem
module Awaaz
  # Properties of audio
  module Properties
    # Calculates the duration (in seconds) of an audio signal given the number of samples and the sample rate.
    #
    # @param samples [Numo::NArray, Array, Object]
    #   The audio samples. This can be a Numo::NArray, Array, or any object
    #   that responds to `.shape` and returns a size array.
    #
    # @param sample_rate [Integer, Float]
    #   The sampling rate (in Hz) of the audio signal.
    #
    # @return [Float]
    #   The duration of the audio signal in seconds. Returns `0.0` if either
    #   the number of samples or the sample rate is non-positive.
    #
    # @example
    #   samples = Numo::DFloat.new(44100) # 1 second of audio at 44.1 kHz
    #   Awaaz.duration(samples, 44100)
    #   # => 1.0
    #
    # @note
    #   The duration is computed as:
    #     samples_count / sample_rate
    #
    # @see https://en.wikipedia.org/wiki/Sampling_(signal_processing)
    def duration(samples, sample_rate)
      samples_count = samples.shape.max
      return 0.0 if samples_count <= 0 || sample_rate <= 0

      samples_count / sample_rate.to_f
    end
  end
end
