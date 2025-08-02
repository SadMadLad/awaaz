module Awaaz
  class Samples
    def initialize(samples, channels, sample_rate)
      @samples = samples
      @channels = channels
      @sample_rate = sample_rate
    end

    def shape
      @samples.shape
    end

    def duration
      (@samples.size.to_f / (@sample_rate.to_i * @channels.to_i)).round(3)
    end

    def to_mono
      return samples if samples.ndim == 1

      samples.mean(0)
    end
  end
end
