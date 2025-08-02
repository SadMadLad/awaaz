# frozen_string_literal: true

require_relative "base_decoder"
require_relative "via_shell"

module Awaaz
  module Decoders
    class WavefileDecoder < BaseDecoder
      include ViaShell

      set_available_options default_available_options

      def load
        validate_options
        validate_file_extension ".wav"

        return shell_load sox_options: { raw: true } unless no_decoders?

        raw_read
      end

      class << self
        def load(...)
          new.load(...)
        end
      end

      private
        def shell?
          from_options(:shell) == true
        end

        def raw_read
          header, samples = File.open(@filename, "rb") do |f|
            [
              parse_header(f.read(44)),
              f.read
            ]
          end

          samples = Numo::Int16.from_string(samples).cast_to(Numo::DFloat) / amplification_factor.to_f

          # TODO
          # resampled_data header, samples

          samples
        end

        def to_mono(samples)
          return samples if samples.ndim == 1
          (samples[0, true] + samples[1, true]) / 2.0
        end

        def resampled_data(header, samples)
          old_sr = header[:sample_rate]
          new_sr = sample_rate
          samples = to_mono(samples) if mono?

          ratio = new_sr.to_f / old_sr
          new_len = (samples.size * ratio).to_i
          x = Numo::DFloat.linspace(0, 1, samples.size)
          xi = Numo::DFloat.linspace(0, 1, new_len)

          linear_interpolate xi, x, samples
        end

        def linear_interpolate(xi, x, samples)
          # TODO
        end

        def parse_header(header)
          {
            chunk_id:        header[0..3],
            file_size:       header[4..7].unpack1("V"),
            format:          header[8..11],
            fmt_chunk:       header[12..15],
            fmt_size:        header[16..19].unpack1("V"),
            audio_format:    header[20..21].unpack1("v"),
            channels:        header[22..23].unpack1("v"),
            sample_rate:     header[24..27].unpack1("V"),
            byte_rate:       header[28..31].unpack1("V"),
            block_align:     header[32..33].unpack1("v"),
            bits_per_sample: header[34..35].unpack1("v"),
            data_chunk:      header[36..39],
            data_size:       header[40..43].unpack1("V")
          }
        end
    end
  end
end
