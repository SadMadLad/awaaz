# frozen_string_literal: true

module Awaaz
  # Audio Features
  module Features
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

      array.concatenate(padded_array, axis: axis)
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
      samples, frame_groups = frame_ranges(samples, frame_size: frame_size, hop_length: hop_length)

      means = Numo::SFloat.zeros(samples.shape[0], frame_groups.length)
      frame_groups.each_with_index do |frame_range, idx|
        means[true, idx] = samples[true, frame_range].rms(axis: 1)
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
      samples.rms
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
    def zcr(samples, frame_size: 2048, hop_length: 512)
      framed_samples, frame_groups = frame_ranges(samples, frame_size: frame_size, hop_length: hop_length)

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
    #
    def zcr_overall(samples)
      ((samples[true, 0...-1] * samples[true, 1..-1]) < 0).count_true(axis: 1) / samples.shape[1].to_f
    end

    # Generates a Hann window of given frame size.
    #
    # A Hann window is commonly used in spectral analysis
    # to reduce spectral leakage before applying an FFT.
    #
    # @param frame_size [Integer] the size of the frame (number of samples per window)
    # @return [Numo::DFloat] the Hann window of length `frame_size`
    def hann_window(frame_size)
      idx = Numo::DFloat.new(frame_size).seq
      0.5 * (1 - Numo::NMath.cos(2 * Math::PI * idx / (frame_size - 1)))
    end

    # Prepares audio samples and parameters for FFT-based feature extraction.
    #
    # @param samples [Numo::NArray]
    #   Multichannel audio samples as a 2D array
    #   (shape: [channels, samples]).
    # @param frame_size [Integer]
    #   Number of samples per frame (FFT window length).
    # @param hop_length [Integer]
    #   Number of samples to shift between consecutive frames.
    #
    # @return [Array]
    #   A tuple containing:
    #   - samples [Numo::NArray] : Windowed audio samples aligned to frames
    #   - ranges [Array<Range>] : Frame index ranges for iteration
    #   - window [Numo::DFloat] : Hann window for FFT
    #   - channels_count [Integer] : Number of audio channels
    #   - freqs_size [Integer] : Number of FFT frequency bins per frame
    #
    # @example
    #   samples, ranges, window, channels_count, freqs_size =
    #     prepare_for_fft(audio, frame_size: 2048, hop_length: 512)
    #
    def prepare_for_fft(samples, frame_size:, hop_length:)
      samples, ranges = frame_ranges(samples, frame_size: frame_size, hop_length: hop_length)
      window = hann_window(frame_size)
      channels_count = samples.shape[0]
      freqs_size = (frame_size / 2) + 1

      [samples, ranges, window, channels_count, freqs_size]
    end

    # Computes the Short-Time Fourier Transform (STFT) of a multi-channel signal.
    #
    # This method applies a sliding Hann window to the input signal, computes
    # the FFT for each frame and each channel, and stores the positive frequency
    # bins into a 3D complex-valued matrix.
    #
    # The resulting STFT matrix has dimensions:
    #   `[channels, frequencies, frames]`
    #
    # @param samples [Numo::NArray] a 2D array of shape [channels, samples]
    #   containing the audio data.
    # @param frame_size [Integer] the size of each FFT frame (default: 2048)
    # @param hop_length [Integer] the number of samples between successive frames (default: 512)
    # @return [Numo::DComplex] a 3D array of shape
    #   `[channels, (frame_size / 2 + 1), frames]` containing the complex STFT values
    #
    # @example Compute STFT for mono audio
    #   samples = Numo::DFloat[[0.0, 1.0, 0.0, -1.0, ...]] # shape: [1, num_samples]
    #   stft_matrix = stft(samples, frame_size: 1024, hop_length: 256)
    #
    def stft(samples, frame_size: 2048, hop_length: 512)
      samples, ranges, window, channels_count, freqs_size = prepare_for_fft(samples, frame_size: frame_size,
                                                                                     hop_length: hop_length)
      stft_matrix = Numo::DComplex.zeros(channels_count, freqs_size, ranges.size)

      ranges.each_with_index do |range, frame_idx|
        channels_count.times do |ch|
          fft_result = Numo::Pocketfft.fft(samples[ch, range] * window)
          stft_matrix[ch, true, frame_idx] = fft_result[0...freqs_size]
        end
      end

      stft_matrix
    end

    ##
    # Computes the FFT (Fast Fourier Transform) of each channel
    # in a multi-channel signal using a Hann window.
    #
    # @param samples [Numo::NArray] A 2D array of shape [channels, samples]
    #   containing the audio data.
    #
    # @return [Numo::DComplex] A 2D complex array of shape
    #   `[channels, samples]` containing the FFT result for each channel.
    #
    def fft(samples)
      window = hann_window(samples.shape[1])
      channels_count = samples.shape[0]
      fft_results = channels_count.times.map do |ch|
        Numo::Pocketfft.fft(samples[ch, true] * window)
      end
      Numo::DComplex[*fft_results]
    end

    ##
    # Computes the frequency bin centers for an FFT.
    #
    # @param frame_size [Integer] The size of the FFT frame (in samples).
    # @param sample_rate [Integer] The sampling rate of the audio (Hz).
    #
    # @return [Numo::DFloat] 1D array of frequency values (Hz)
    #   corresponding to FFT bins. Shape: `[frame_size/2 + 1]`.
    #
    def frequency_bins(frame_size, sample_rate)
      Numo::DFloat.new((frame_size / 2) + 1).seq * (sample_rate.to_f / frame_size)
    end

    ##
    # Computes the magnitude spectrum of a single frame using an FFT.
    #
    # @param frame [Numo::NArray] 1D array of audio samples for a single frame.
    #
    # @return [Numo::DFloat] 1D array of magnitude values for each FFT bin.
    #
    def frame_magnitude(frame)
      Numo::Pocketfft.rfft(frame).abs
    end

    ##
    # Computes the spectral centroid of a single frame.
    #
    # The spectral centroid is the "center of mass" of the spectrum
    # and is often associated with the perceived brightness of a sound.
    #
    # @param freqs [Numo::DFloat] 1D array of frequency bin centers.
    # @param magnitude [Numo::DFloat] 1D array of magnitude values
    #   corresponding to each frequency bin.
    #
    # @return [Float] The spectral centroid in Hz for the given frame.
    #
    def compute_centroid(freqs, magnitude)
      mag_sum = magnitude.sum
      return 0 if mag_sum.zero?

      (freqs * magnitude).sum / mag_sum
    end

    ##
    # Computes the spectral centroid trajectory of an audio signal.
    #
    # This method frames the signal, applies a Hann window,
    # computes the FFT magnitudes, and calculates the centroid
    # for each frame. The result is a time series of centroids.
    #
    # @param samples [Numo::NArray] A 2D array of shape [channels, samples].
    # @param frame_size [Integer] Size of each analysis frame (default: 2048).
    # @param hop_length [Integer] Step size between frames in samples (default: 512).
    # @param sample_rate [Integer] Sampling rate of the audio in Hz (default: 22050).
    #
    # @return [Numo::DFloat] 2D array of spectral centroids with shape
    #   `[channels, n_frames]`.
    #
    # @example
    #   centroids = spectral_centroids(samples, frame_size: 1024, hop_length: 256, sample_rate: 44100)
    #   puts centroids.shape # => [channels, n_frames]
    #
    def spectral_centroids(samples, frame_size: 2048, hop_length: 512, sample_rate: 22_050)
      samples, ranges, window, channels_count = prepare_for_fft(samples, frame_size: frame_size, hop_length: hop_length)
      freqs = frequency_bins(frame_size, sample_rate)
      centroid_matrix = Numo::DFloat.zeros(channels_count, ranges.size)

      ranges.each_with_index do |range, frame_idx|
        channels_count.times do |ch|
          frame = samples[ch, range] * window
          magnitude = frame_magnitude(frame)
          centroid_matrix[ch, frame_idx] = compute_centroid(freqs, magnitude)
        end
      end

      centroid_matrix
    end

    # Computes the bandwidth for a single frame.
    #
    # @param freqs [Numo::DFloat] Frequency bins (Hz)
    # @param magnitude [Numo::DFloat] Magnitude spectrum for the frame
    # @param centroid [Float] Spectral centroid for the frame (Hz)
    # @param power [Integer] Power/exponent used for bandwidth calculation (commonly 2)
    # @return [Float] Spectral bandwidth for the frame
    def compute_bandwidth(freqs, magnitude, centroid, power)
      mag_sum = magnitude.sum
      return 0 if mag_sum.zero?

      diff = (freqs - centroid).abs**power
      value = (magnitude * diff).sum / mag_sum
      value**(1.0 / power)
    end

    # Computes the spectral bandwidth over time for a signal.
    #
    # @param samples [Numo::DFloat] Input samples (channels x samples)
    # @param frame_size [Integer] FFT window size (default: 2048)
    # @param hop_length [Integer] Step size between frames (default: 512)
    # @param sample_rate [Integer] Sampling rate of the audio signal (default: 22050 Hz)
    # @param power [Integer] Exponent for bandwidth calculation (default: 2)
    # @return [Numo::DFloat] Spectral bandwidth matrix (channels x frames)
    def spectral_bandwidth(samples, frame_size: 2048, hop_length: 512, sample_rate: 22_050, power: 2)
      samples, ranges, window, channels_count = prepare_for_fft(samples, frame_size: frame_size, hop_length: hop_length)
      freqs = frequency_bins(frame_size, sample_rate)
      bandwidth_matrix = Numo::DFloat.zeros(channels_count, ranges.size)

      ranges.each_with_index do |range, frame_idx|
        channels_count.times do |ch|
          magnitude = frame_magnitude(samples[ch, range] * window)
          centroid = compute_centroid(freqs, magnitude)
          bandwidth_matrix[ch, frame_idx] = compute_bandwidth(freqs, magnitude, centroid, power)
        end
      end

      bandwidth_matrix
    end

    # Computes the spectral rolloff for a single frame.
    #
    # @param spectrum [Numo::DFloat] Magnitude spectrum for the frame
    # @param freqs [Numo::DFloat] Frequency bins (Hz)
    # @param threshold [Float] Proportion of spectral energy to retain (default: 0.85)
    # @return [Float] Roll-off frequency (Hz) for the frame
    def rolloff_for_frame(spectrum, freqs, threshold)
      total_energy = spectrum.sum
      return 0.0 if total_energy.zero?

      cumsum = spectrum.cumsum
      threshold_energy = threshold * total_energy

      rolloff_bin = cumsum.ge(threshold_energy).where[0]
      rolloff_bin ||= freqs.size - 1

      freqs[rolloff_bin]
    end

    # Computes the spectral rolloff over time for a signal.
    #
    # Spectral rolloff is the frequency below which a fixed percentage
    # (threshold) of the total spectral energy is contained.
    #
    # @param samples [Numo::DFloat] Input samples (channels x samples)
    # @param frame_size [Integer] FFT window size (default: 2048)
    # @param hop_length [Integer] Step size between frames (default: 512)
    # @param sample_rate [Integer] Sampling rate of the audio signal (default: 22050 Hz)
    # @param threshold [Float] Proportion of spectral energy to retain (default: 0.85)
    # @return [Numo::DFloat] Spectral rolloff matrix (channels x frames)
    def spectral_rolloff(samples, frame_size: 2048, hop_length: 512, sample_rate: 22_050, threshold: 0.85)
      stft_matrix = stft(samples, frame_size: frame_size, hop_length: hop_length).abs
      channels, _freqs_size, frames_size = stft_matrix.shape
      freqs = frequency_bins(frame_size, sample_rate)

      rolloff_matrix = Numo::DFloat.zeros(channels, frames_size)

      frames_size.times do |frame_idx|
        channels.times do |ch|
          rolloff_matrix[ch, frame_idx] = rolloff_for_frame(
            stft_matrix[ch, true, frame_idx], freqs, threshold
          )
        end
      end

      rolloff_matrix
    end

    # Convert frame indices to time in seconds.
    #
    # This method maps analysis frame indices (or total frame count) into
    # corresponding time positions in seconds, similar to `librosa.frames_to_time`.
    #
    # @param frames [Integer, Numo::NArray] Either a single frame index,
    #   or a Numo array of shape (n_channels, n_frames) from which the total
    #   number of frames is inferred.
    # @param hop_length [Integer] Number of audio samples between adjacent frames.
    #   Defaults to 512.
    # @param sample_rate [Integer] Sampling rate of the audio signal in Hz.
    #   Defaults to 22,050 Hz.
    #
    # @return [Numo::DFloat] A 1-D Numo array of times (in seconds) corresponding
    #   to each frame index. If `frames` is an Integer, the return value spans
    #   from frame 0 up to `frames - 1`. If `frames` is a Numo array, the return
    #   value spans the number of frames inferred from `frames.shape[1]`.
    #
    # @example Using total frame count
    #   frames_to_time(100, hop_length: 512, sample_rate: 22050)
    #   # => Numo::DFloat[0.0, 0.0232, ..., 2.3121]
    #
    # @example Using a spectrogram matrix
    #   samples = Numo::DFloat.new(2, 500) # 2 channels, 500 frames
    #   frames_to_time(samples, hop_length: 512, sample_rate: 22050)
    #   # => Numo::DFloat[0.0, 0.0232, ..., 11.61]
    #
    def frames_to_time(frames, hop_length: 512, sample_rate: 22_050)
      frames_size = frames.shape[1] unless frames.is_a?(Integer)
      Numo::DFloat[0...frames_size] * hop_length / sample_rate.to_f
    end

    ##
    # Computes the spectral flatness of an audio signal.
    #
    # Spectral flatness measures how noise-like a signal is, as opposed to being tone-like.
    # A value closer to 1.0 indicates the spectrum is flat (similar to white noise),
    # while values closer to 0.0 indicate a peaky spectrum (like a sine wave or harmonic-rich signal).
    #
    # @param samples [Numo::NArray]
    #   The input audio samples (1D array).
    #
    # @param frame_size [Integer] (2048)
    #   The size of each FFT window (frame). Larger sizes give better frequency
    #   resolution but worse time resolution.
    #
    # @param hop_length [Integer] (512)
    #   The number of samples to shift between consecutive FFT frames. Smaller values
    #   provide more overlap and smoother results.
    #
    # @param amin [Float] (1e-10)
    #   A small constant added for numerical stability, preventing log(0) or division by zero.
    #
    # @param power [Integer] (2)
    #   The power to which the magnitude spectrum is raised. Typically 2 to work with
    #   power spectrograms.
    #
    # @return [Numo::DFloat]
    #   A 1D Numo::DFloat array containing the spectral flatness values for each frame.
    #
    # @example Compute spectral flatness for an audio clip
    #   samples = Awaaz::Utils::Soundread.new("audio.wav").read
    #   flatness = spectral_flatness(samples, frame_size: 1024, hop_length: 256)
    #   puts flatness.shape
    #
    def spectral_flatness(samples, frame_size: 2048, hop_length: 512, amin: 1e-10, power: 2)
      stft_matrix = stft(samples, frame_size: frame_size, hop_length: hop_length).abs
      stft_matrix = Numo::DFloat.maximum(amin, stft_matrix**power)

      gms = Numo::DFloat::Math.exp Numo::DFloat::Math.log(stft_matrix).mean(axis: -2)
      ams = stft_matrix.mean(axis: -2)

      gms / ams
    end
  end
end
