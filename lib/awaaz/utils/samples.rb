# frozen_string_literal: true

module Awaaz
  module Utils
    class Samples
      def initialize(sample_rate, channels, samples, mono: false)
        @sample_rate = sample_rate
        @channels = channels
        @mono = mono
        @samples = processed_samples samples
        to_mono if mono?
      end

      def shape
        @samples.shape
      end

      def duration
        (@samples.size.to_f / (@sample_rate.to_i * @channels.to_i)).round(3)
      end

      def to_mono
        return @samples if @samples.ndim == 1

        @samples = @samples.mean(0)
        @channels = 1
      end

      # For debugging
      def print_details
        p "Samples Max: #{@samples.max}, Samples Min: #{@samples.min}"
        p "Shape: #{@samples.shape}"
        p "Channels Count: #{@channels}"
      end

      private

      def processed_samples(input_samples)
        input_samples.reshape(input_samples.size / @channels, @channels).transpose
      end

      def mono?
        @mono == true || @channels == 1
      end
    end
  end
end
