module Awaaz
  module Utils
    class Soundread
      SUPPORTED_EXTENSIONS = %w[.wav].freeze

      def initialize(filename, resample_options: default_resample_options)
        @filename = filename
        @resample_options = resample_options || {}
      end

      def read
        validate_support
        soundfile, sample_rate, frames, channels = open_file
        samples = parse_soundfile soundfile, frames, channels
        close_soundfile soundfile

        resample samples, sample_rate, channels
      end

      private
        def default_resample_options
          { output_rate: 22050 }
        end

        def validate_support
          return if supported?

          raise ArgumentError, "File extension not supported. Supported files: #{SUPPORTED_EXTENSIONS.join(',')}"
        end

        def supported?
          SUPPORTED_EXTENSIONS.include? File.extname(@filename)
        end

        def open_file
          info = Extensions::Soundfile::SF_INFO.new
          sndfile = Extensions::Soundfile.sf_open(@filename, Extensions::Soundfile::SFM_READ, info.to_ptr)

          raise Awaaz::AudioreadError, "Could not read the audio file" if sndfile.null?

          sample_rate, frames, channels = info[:samplerate], info[:frames], info[:channels]
          [sndfile, sample_rate, frames, channels]
        end

        def parse_soundfile(soundfile, frames, channels)
          buffer = FFI::MemoryPointer.new(:float, frames * channels)
          read_frames = Extensions::Soundfile.sf_readf_float(soundfile, buffer, frames)
          samples = Numo::SFloat.cast buffer.read_array_of_float(read_frames * channels)

          samples
        end

        def close_soundfile(soundfile)
          Extensions::Soundfile.sf_close soundfile
        end

        def resample(samples, sample_rate, channels)
          valid_options = %i[output_rate sampling_option]

          @resample_options.transform_keys!(&:to_sym)
          @resample_options.keys.each do |key|
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
