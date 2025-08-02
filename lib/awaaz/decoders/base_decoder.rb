# frozen_string_literal: true

module Awaaz
  module Decoders
    class BaseDecoder
      class << self
        def default_available_options
          %i[amplification_factor decoder sample_rate channels]
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

      def initialize(filename, **options)
        @filename = filename
        @options = options
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

        def validate_options
          return if @options.empty?

          @options.each_key do |key|
            next if available_options.include?(key.to_sym)

            raise ArgumentError, "Invalid options key passed: #{key}. Available options: #{available_options.join}"
          end
        end

        def config
          Awaaz.config
        end

        def no_decoders?
          config.no_decoders?
        end

        def from_options(key)
          @options[key.to_sym] || @options[key.to_s]
        end
    end
  end
end
