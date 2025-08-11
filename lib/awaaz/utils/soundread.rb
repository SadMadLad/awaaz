# frozen_string_literal: true

module Awaaz
  module Utils
    ##
    # A utility class for reading and optionally resampling audio files.
    #
    # This class supports reading `.wav` files using {Extensions::Soundfile}
    # and can automatically resample them using {Utils::Resample}.
    #
    # @example Read and resample a WAV file
    #   reader = Awaaz::Utils::Soundread.new("audio.wav", resample_options: { output_rate: 44100 })
    #   samples, channels, rate = reader.read
    #
    # @note Currently, only `.wav` files are supported.
    #
    class Soundread
      ##
      # Supported audio file extensions.
      #
      # @return [Array<String>] List of supported file extensions.
      #
      SUPPORTED_EXTENSIONS = %w[.wav].freeze

      ##
      # Creates a new Soundread instance.
      #
      # @param filename [String] Path to the audio file to read.
      # @param resample_options [Hash] Options for resampling the audio.
      #   - `:output_rate` [Integer] Output sample rate (default: `22050`)
      #   - `:sampling_option` [Symbol] Resampling algorithm (default: `:sinc_fastest`)
      #
      def initialize(filename, resample_options: default_resample_options)
        @filename = filename
        @resample_options = resample_options || {}
      end

      ##
      # Reads the audio file, returning its samples and metadata.
      #
      # @return [Array<(Numo::SFloat, Integer, Integer)>]
      #   A tuple containing:
      #   - samples [Numo::SFloat] — Audio samples as a Numo array.
      #   - channels [Integer] — Number of channels in the audio.
      #   - output_rate [Integer] — Sample rate of the returned audio.
      #
      # @raise [ArgumentError] If the file extension is unsupported.
      # @raise [Awaaz::AudioreadError] If the file cannot be opened.
      #
      def read
        validate_support
        soundfile, sample_rate, frames, channels = open_file
        samples = parse_soundfile(soundfile, frames, channels)
        close_soundfile(soundfile)

        resample(samples, sample_rate, channels)
      end

      private

      ##
      # Default resampling options.
      #
      # @return [Hash] Default options with `:output_rate => 22050`.
      #
      def default_resample_options
        { output_rate: 22_050 }
      end

      ##
      # Ensures the file format is supported.
      #
      # @raise [ArgumentError] If the file extension is not in {SUPPORTED_EXTENSIONS}.
      #
      def validate_support
        return if supported?

        raise ArgumentError, "File extension not supported. Supported files: #{SUPPORTED_EXTENSIONS.join(",")}"
      end

      ##
      # Checks if the file extension is supported.
      #
      # @return [Boolean] `true` if supported, `false` otherwise.
      #
      def supported?
        SUPPORTED_EXTENSIONS.include?(File.extname(@filename))
      end

      ##
      # Opens the audio file for reading.
      #
      # @return [Array<(FFI::Pointer, Integer, Integer, Integer)>]
      #   A tuple containing:
      #   - soundfile [FFI::Pointer] — Pointer to the opened sound file.
      #   - sample_rate [Integer] — Sample rate of the audio file.
      #   - frames [Integer] — Number of frames in the file.
      #   - channels [Integer] — Number of channels in the file.
      #
      # @raise [Awaaz::AudioreadError] If the file cannot be opened.
      #
      def open_file
        info = Extensions::Soundfile::SF_INFO.new
        sndfile = Extensions::Soundfile.sf_open(@filename, Extensions::Soundfile::SFM_READ, info.to_ptr)

        raise Awaaz::AudioreadError, "Could not read the audio file" if sndfile.null?

        sample_rate = info[:samplerate]
        frames = info[:frames]
        channels = info[:channels]
        [sndfile, sample_rate, frames, channels]
      end

      ##
      # Reads the raw samples from the file and converts them into a Numo array.
      #
      # @param soundfile [FFI::Pointer] Open sound file pointer.
      # @param frames [Integer] Number of frames to read.
      # @param channels [Integer] Number of channels in the file.
      # @return [Numo::SFloat] The audio samples.
      #
      def parse_soundfile(soundfile, frames, channels)
        buffer = FFI::MemoryPointer.new(:float, frames * channels)
        read_frames = Extensions::Soundfile.sf_readf_float(soundfile, buffer, frames)
        Numo::SFloat.cast(buffer.read_array_of_float(read_frames * channels))
      end

      ##
      # Closes the open sound file.
      #
      # @param soundfile [FFI::Pointer] Open sound file pointer.
      # @return [void]
      #
      def close_soundfile(soundfile)
        Extensions::Soundfile.sf_close(soundfile)
      end

      ##
      # Resamples the audio if necessary.
      #
      # @param samples [Numo::SFloat] The input samples.
      # @param sample_rate [Integer] Original sample rate.
      # @param channels [Integer] Number of channels.
      # @return [Array<(Numo::SFloat, Integer, Integer)>]
      #
      # @raise [ArgumentError] If an invalid resample option key is passed.
      #
      def resample(samples, sample_rate, channels)
        valid_options = %i[output_rate sampling_option]

        @resample_options.transform_keys!(&:to_sym)
        @resample_options.each_key do |key|
          next if valid_options.include?(key)

          raise ArgumentError, "Invalid option: #{key}. Available options: #{valid_options.join}"
        end

        output_rate, sampling_option = @resample_options.values_at(:output_rate, :sampling_rate)
        sampling_option ||= :sinc_fastest

        [
          Utils::Resample.read_and_resample_numo(samples, sample_rate, output_rate, sampling_option:),
          channels,
          output_rate
        ]
      end
    end
  end
end
