module Awaaz
  class Samples
    attr_reader :samples

    def initialize(sample_rate, channels, samples)
      @sample_rate = sample_rate
      @channels = channels
      @samples = processed_samples samples
    end

    def shape
      @samples.shape
    end

    def duration
      (@samples.size.to_f / (@sample_rate.to_i * @channels.to_i)).round(3)
    end

    def to_mono
      return @samples if @samples.ndim == 1

      @samples.mean(0)
    end

    private
      def processed_samples(input_samples)
        input_samples.reshape(input_samples.size / @channels, @channels).transpose
      end
  end
end
