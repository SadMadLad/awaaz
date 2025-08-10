module Awaaz
  module Utils
    module ViaShell
      private
        def shell_load(...)
          shell_command = build_shell_command(...)
          load_samples shell_command
        end

        def build_shell_command(ffmpeg_options: {}, mpg123_options: {}, sox_options: {})
          set_decoder

          case @decoder
          when :ffmpeg then build_ffmpeg_command(@filename, **ffmpeg_options)
          when :mpg123 then build_mpg123_command(@filename, **mpg123_options)
          when :sox then build_sox_command(@filename, **sox_options)
          end
        end

        def build_ffmpeg_command(filename, **_opts)
          ffmpeg_command = Utils::ShellCommandBuilder.new(:ffmpeg)

          ffmpeg_command
            .add_flag("-nostdin")
            .add_option("-v", "quiet")
            .add_option("-i", filename)
            .add_option("-f", "s16le")
            .add_option("-acodec", "pcm_s16le")
            .add_option("-ac", channels_flag)
            .add_option("-ar", sample_rate)
            .add_arg("-")
        end

        def build_mpg123_command(filename, **_opts)
          mpg123_command = Utils::ShellCommandBuilder.new(:mpg123)

          mpg123_command
            .add_flag("-q")
            .add_option("-f", amplification_factor)
            .add_option("-r", sample_rate)
            .add_flag("-s")
            .add_arg(filename)
          mpg123_command.add_flag(channels_flag) if mono?
          mpg123_command
        end

        def build_sox_command(filename, **opts)
          sox_command = Utils::ShellCommandBuilder.new(:sox)

          sox_command
            .add_arg(filename)
            .add_option("-r", sample_rate)
            .add_option("-e", "signed")
            .add_option("-b", 16)
            .add_option("-c", channels_flag)
          sox_command.add_option("-t", "raw") if opts[:raw]
          sox_command.add_arg("-")
        end

        def load_samples(shell_command)
          shell_command = shell_command.command unless shell_command.is_a?(String)
          raw_audio = IO.popen(shell_command, "rb", &:read)
          samples = Numo::Int16.from_string(raw_audio).cast_to(Numo::DFloat) / amplification_factor.to_f

          Utils::Samples.new(sample_rate.to_i, num_channels, samples)
        end

        def set_decoder
          return @decoder if @decoder
          decoder_from_options = from_options(:decoder)&.to_sym

          @decoder = if decoder_from_options && config.potential_decoders.include?(decoder_from_options)
            decoder_from_options
          elsif config.ffmpeg?
            :ffmpeg
          elsif config.mpg123?
            :mpg123
          elsif config.sox?
            :sox
          end

          potential_decoders = config.potential_decoders.join(", ")
          raise Awaaz::DecoderNotFound,
                "No available decoder detected to decode mp3 files. Potential decoders: #{potential_decoders}" if @decoder.nil?
        end

        def sample_rate
          (from_options(:sample_rate) || 22_050).to_s
        end

        def channels_flag
          return "-m" if mpg123? && mono?
          num_channels
        end

        def num_channels
          return 1 if mono?

          2
        end

        def mono
          from_options(:mono) || false
        end

        def mono?
          mono
        end

        def stereo?
          !mono?
        end

        def mpg123?
          set_decoder == :mpg123
        end

        def amplification_factor
          (from_options(:amplification_factor) || 32_768).to_i
        end
    end
  end
end

