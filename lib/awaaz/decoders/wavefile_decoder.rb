# frozen_string_literal: true

module Awaaz
  module Decoders
    ##
    # The WavefileDecoder is responsible for decoding `.wav` audio files
    # into raw PCM data that can be processed by the Awaaz audio pipeline.
    #
    # This decoder supports multiple decoding strategies:
    #
    # 1. **Soundread** — a Ruby-level `.wav` file reader.
    # 2. **Shell-based decoding** — for raw audio extraction.
    #
    # The decoder will choose a decoding method based on availability
    # of decoders and the configured options.
    #
    # @see Awaaz::Decoders::BaseDecoder
    # @see Awaaz::Utils::ViaShell
    #
    class WavefileDecoder < BaseDecoder
      include Utils::ViaShell

      # Sets the available decoding options for this decoder.
      # Defaults to the base options plus the `:soundread` option.
      #
      # @!scope class
      set_available_options default_available_options + [:soundread]

      ##
      # Loads and decodes a `.wav` file into raw PCM data.
      #
      # @raise [AgumentError]
      #   if the file does not have a `.wav` extension.
      #
      # @return [Array<(Numo::NArray, Integer, Integer)>]
      #   Returns an array containing:
      #   - samples: A [Numo::NArray] of decoded audio samples
      #   - sample_rate: Integer sample rate (Hz)
      #   - channels: Integer number of audio channels
      #
      # @note The decoding method is chosen dynamically:
      #   - If there are no available decoders, or if `:soundread` is enabled,
      #     it will use the {#soundread} method.
      #   - Otherwise, it will use shell based decoding.
      #
      def load
        output_data = if no_decoders? || soundread?
                        soundread
                      else
                        shell_load sox_options: { raw: true }
                      end

        process(*output_data)
      end
    end
  end
end
