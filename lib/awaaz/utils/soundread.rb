# frozen_string_literal: true

module Awaaz
  module Utils
    ##
    # A helper that mimics librosa.load using libsndfile via FFI.
    #
    # - Always returns Float32 samples normalized in [-1.0, 1.0]
    # - Preserves channel structure (returns shape `[channels, frames]`)
    # - Returns `[data, channels, sr]` where:
    #   * `data` = Numo::SFloat array (2D, shape: channels x frames)
    #   * `channels` = Integer number of channels
    #   * `sr` = sample rate (Integer)
    #
    # @example
    #   reader = Awaaz::Utils::Soundread.new("audio.wav")
    #   data, channels, sr = reader.read
    #
    class Soundread
      ##
      # Initializes a Soundread instance.
      #
      # @param filename [String] Path to the audio file to read.
      # @param resampling_options [Hash] Optional resampling configuration.
      #
      def initialize(filename, **resampling_options)
        @filename = filename
        @resampling_options = resampling_options
      end

      ##
      # Reads the audio file, returning samples, number of channels, and sample rate.
      #
      # @return [Array<(Numo::SFloat, Integer, Integer)>]
      #   - data [Numo::SFloat] Audio samples, shape = `[channels, frames]`
      #   - channels [Integer] Number of channels
      #   - sr [Integer] Sample rate
      #
      # @raise [ArgumentError] If the file cannot be opened.
      #
      def read
        info, sndfile = open_file
        frames, channels, sr = extract_info(info)

        buffer, read_frames = read_buffer(sndfile, frames, channels)
        close_file(sndfile)

        data = process_data(buffer, read_frames, channels)
        [resample(data, sr, channels), channels, sr]
      end

      private

      def resample(samples, sample_rate, channels)
        validate_resampling_options

        output_rate, sampling_option = @resampling_options.values_at(:output_rate, :sampling_rate)
        sampling_option ||= :linear

        return samples if output_rate == sample_rate || @resampling_options.empty?

        Utils::Resample.read_and_resample(samples, sample_rate, output_rate, channels, sampling_option:)
      end

      def validate_resampling_options
        valid_options = %i[output_rate sampling_option]

        @resampling_options.transform_keys!(&:to_sym)
        @resampling_options.each_key do |key|
          next if valid_options.include?(key)

          raise ArgumentError, "Invalid option: #{key}. Available options: #{valid_options.join}"
        end
      end

      ##
      # Opens the file and retrieves SF_INFO metadata.
      #
      # @return [Array<(Awaaz::Extensions::Soundfile::SF_INFO, FFI::Pointer)>]
      #
      # @raise [ArgumentError] If the file cannot be opened.
      #
      def open_file
        info = Awaaz::Extensions::Soundfile::SF_INFO.new
        sndfile = Awaaz::Extensions::Soundfile.sf_open(
          @filename,
          Awaaz::Extensions::Soundfile::SFM_READ,
          info
        )

        raise ArgumentError, "Could not open file: #{@filename}" if sndfile.null?

        [info, sndfile]
      end

      ##
      # Extracts frames, channels, and sample rate from SF_INFO.
      #
      # @param info [Awaaz::Extensions::Soundfile::SF_INFO]
      # @return [Array<(Integer, Integer, Integer)>] frames, channels, sr
      #
      def extract_info(info)
        [info[:frames], info[:channels], info[:samplerate]]
      end

      ##
      # Reads raw audio frames into a memory buffer.
      #
      # @param sndfile [FFI::Pointer] Opened sound file.
      # @param frames [Integer] Number of frames to read.
      # @param channels [Integer] Number of channels.
      #
      # @return [Array<(FFI::MemoryPointer, Integer)>] buffer and number of read frames
      #
      def read_buffer(sndfile, frames, channels)
        buffer = FFI::MemoryPointer.new(:float, frames * channels)
        read_frames = Awaaz::Extensions::Soundfile.sf_readf_float(sndfile, buffer, frames)
        [buffer, read_frames]
      end

      ##
      # Closes the open sound file.
      #
      # @param sndfile [FFI::Pointer]
      # @return [void]
      #
      def close_file(sndfile)
        Awaaz::Extensions::Soundfile.sf_close(sndfile)
      end

      ##
      # Converts the buffer into a Numo::SFloat array and reshapes to `[channels, frames]`.
      #
      # @param buffer [FFI::MemoryPointer]
      # @param read_frames [Integer] Number of frames read.
      # @param channels [Integer] Number of channels.
      # @return [Numo::SFloat] Audio data of shape `[channels, frames]`.
      #
      def process_data(buffer, read_frames, channels)
        data = Numo::SFloat[*buffer.read_array_of_float(read_frames * channels)]
        data.reshape(read_frames, channels).transpose
      end
    end
  end
end
