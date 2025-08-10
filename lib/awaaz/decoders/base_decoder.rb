# frozen_string_literal: true

module Awaaz
  module Decoders
    class BaseDecoder
      class << self
        def default_available_options
          %i[amplification_factor decoder sample_rate mono]
        end

        def set_available_options(provided_available_options = default_available_options)
          @available_options = provided_available_options
        end

        attr_reader :available_options

        def load(filename, ...)
          new(filename).load
        end
      end

      set_available_options

      def initialize(filename, **)
        @filename = filename
        @options = Utils::SoundConfig.new(available_options, **)
      end

      def load
        raise NotImplementedError
      end

      def available_options
        self.class.available_options
      end

      protected

      def validate_file_extension(file_extension)
        raise ArgumentError, "Not a #{file_extension} file" unless File.extname(@filename) == file_extension
      end

      def config = Awaaz.config

      %i[no_decoders? potential_decoders].each do |config_method|
        define_method(config_method) { config.public_send(config_method) }
      end

      %i[sample_rate num_channels decoder_option mono mono? stereo? amplification_factor].each do |option_key|
        define_method(option_key) { @options.public_send(option_key) }
      end
    end
  end
end
