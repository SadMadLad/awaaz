# frozen_string_literal: true

module Awaaz
  module Decoders
    # Abstract base class for audio decoders in the Awaaz gem.
    #
    # Provides common configuration handling, option management, and helper
    # methods for working with audio data. Subclasses are expected to implement
    # the {#load} method to perform the actual decoding process.
    #
    # @abstract
    class BaseDecoder
      class << self
        # @return [Array<Symbol>] The default set of options available to all decoders.
        def default_available_options
          %i[amplification_factor decoder sample_rate mono]
        end

        # Sets the list of available options for this decoder class.
        #
        # @param provided_available_options [Array<Symbol>] the list of available option keys.
        # @return [void]
        def set_available_options(provided_available_options = default_available_options)
          @available_options = provided_available_options
        end

        # @return [Array<Symbol>] The currently available option keys for this decoder class.
        attr_reader :available_options

        # Loads audio from a given file using this decoder.
        #
        # @param filename [String] The path to the audio file to load.
        # @return [Object] The decoded audio data.
        #
        # @see #initialize
        def load(filename, ...)
          new(filename, ...).load
        end
      end

      set_available_options

      # @param filename [String] Path to the audio file to decode.
      def initialize(filename, **)
        @filename = filename
        @options = Utils::SoundConfig.new(available_options, **)
      end

      # Loads audio data.
      #
      # This method must be implemented by subclasses to perform
      # the actual decoding of the file.
      #
      # @abstract
      # @raise [NotImplementedError] if called on the base class.
      def load
        raise NotImplementedError
      end

      # @return [Array<Symbol>] The available options for this instance.
      def available_options
        self.class.available_options
      end

      protected

      # Reads audio data from the file using {Utils::Soundread}.
      #
      # @return [Array<(Numo::SFloat, Integer, Integer)>]
      #   A tuple containing:
      #   - audio samples as a Numo::SFloat array
      #   - number of channels
      #   - sample rate
      def soundread
        Utils::Soundread.new(@filename).read
      end

      # Processes the decoded audio samples by reshaping and optionally converting to mono.
      #
      # @param input_samples [Numo::DFloat] The raw decoded samples.
      # @param channels [Integer] Number of channels in the input.
      # @param sample_rate [Integer] The sample rate of the input.
      # @return [Array<(Numo::DFloat, Integer)>] Processed samples and the sample rate.
      def process(input_samples, channels, sample_rate)
        input_samples = input_samples.reshape(channels, input_samples.size / channels)
        input_samples = input_samples.mean(0) if mono?

        [input_samples, sample_rate]
      end

      # Validates that the file extension matches the expected extension.
      #
      # @param file_extension [String] Expected file extension (e.g., ".mp3").
      # @raise [ArgumentError] if the file extension does not match.
      def validate_file_extension(file_extension)
        raise ArgumentError, "Not a #{file_extension} file" unless File.extname(@filename) == file_extension
      end

      # @return [Awaaz::Config] The global Awaaz configuration.
      def config = Awaaz.config

      # Delegates config methods to the {Awaaz::Config} instance.
      %i[no_decoders? potential_decoders].each do |config_method|
        define_method(config_method) { config.public_send(config_method) }
      end

      # Delegates option accessors to the {Utils::SoundConfig} instance.
      %i[
        sample_rate num_channels decoder_option mono mono?
        stereo? amplification_factor soundread?
      ].each do |option_key|
        define_method(option_key) { @options.public_send(option_key) }
      end
    end
  end
end
