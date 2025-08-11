# frozen_string_literal: true

module Awaaz
  module Utils
    ##
    # Utility module providing shell-based audio decoding support for decoder classes.
    #
    # This module is intended to be mixed into decoder classes that rely on external
    # tools such as `ffmpeg`, `mpg123`, or `sox` to decode audio files. It builds the
    # appropriate shell commands, executes them, and converts the raw audio data into
    # {Numo::NArray} samples.
    #
    # @note This module is `private` and its methods are meant to be used internally by decoders.
    #
    # @example Using within a decoder
    #   class Mp3Decoder < B
    #     include Awaaz::Utils::ViaShell
    #
    #     def load
    #       process(*shell_load(sox_options: { raw: true }))
    #     end
    #   end
    #
    module ViaShell
      private

      ##
      # Loads audio samples by building and executing a shell command.
      #
      # @param args [Hash] Options to pass through to {#build_shell_command}.
      # @return [Array<(Numo::DFloat, Integer, Integer)>] An array containing:
      #   - samples (`Numo::DFloat`)
      #   - number of channels (`Integer`)
      #   - sample rate (`Integer`)
      def shell_load(...)
        shell_command = build_shell_command(...)
        load_samples(shell_command)
      end

      ##
      # Builds the appropriate shell command for the detected decoder.
      #
      # @param ffmpeg_options [Hash] Additional options for `ffmpeg` commands.
      # @param mpg123_options [Hash] Additional options for `mpg123` commands.
      # @param sox_options [Hash] Additional options for `sox` commands.
      # @return [Utils::ShellCommandBuilder] The command builder object.
      def build_shell_command(ffmpeg_options: {}, mpg123_options: {}, sox_options: {})
        set_decoder

        case @decoder
        when :ffmpeg then build_ffmpeg_command(@filename, **ffmpeg_options)
        when :mpg123 then build_mpg123_command(@filename, **mpg123_options)
        when :sox    then build_sox_command(@filename, **sox_options)
        end
      end

      ##
      # Builds an `ffmpeg` command to decode audio.
      #
      # @param filename [String] Path to the audio file.
      # @return [Utils::ShellCommandBuilder] The configured command.
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

      ##
      # Builds a `mpg123` command to decode audio.
      #
      # @param filename [String] Path to the audio file.
      # @return [Utils::ShellCommandBuilder] The configured command.
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

      ##
      # Builds a `sox` command to decode audio.
      #
      # @param filename [String] Path to the audio file.
      # @param opts [Hash] Additional options (e.g., `raw: true`).
      # @return [Utils::ShellCommandBuilder] The configured command.
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

      ##
      # Executes the shell command and loads raw audio samples.
      #
      # @param shell_command [String, Utils::ShellCommandBuilder] The shell command to execute.
      # @return [Array<(Numo::DFloat, Integer, Integer)>] An array containing:
      #   - samples (`Numo::DFloat`)
      #   - number of channels (`Integer`)
      #   - sample rate (`Integer`)
      def load_samples(shell_command)
        shell_command = shell_command.command unless shell_command.is_a?(String)
        raw_audio = IO.popen(shell_command, "rb", &:read)
        samples = Numo::Int16.from_string(raw_audio).cast_to(Numo::DFloat) / amplification_factor.to_f

        [samples, num_channels, sample_rate.to_i]
      end

      # This method first returns the already-set `@decoder` if present.
      # If no decoder is set, it attempts to determine an appropriate decoder
      # by calling {#choose_decoder}. If no decoder can be determined, it raises
      # a {Awaaz::DecoderNotFound} error with a list of potential decoders.
      #
      # @raise [Awaaz::DecoderNotFound] if no decoder could be determined.
      # @return [Symbol] The chosen decoder symbol (`:ffmpeg`, `:mpg123`, `:sox`, or a user-provided option).
      def set_decoder
        return @decoder if @decoder

        @decoder = choose_decoder
        return if @decoder

        raise Awaaz::DecoderNotFound,
              "No available decoder detected to decode mp3 files. " \
              "Potential decoders: #{config.potential_decoders.join(", ")}"
      end

      # Chooses an appropriate decoder based on user preference and system capabilities.
      #
      # Priority order:
      # 1. User-specified decoder option (if valid).
      # 2. `ffmpeg` if available.
      # 3. `mpg123` if available.
      # 4. `sox` if available.
      #
      # @return [Symbol, nil] The chosen decoder symbol (`:ffmpeg`, `:mpg123`, `:sox`,
      # or a user-provided option), or `nil` if none is available.
      def choose_decoder
        return decoder_option if decoder_option && potential_decoders.include?(decoder_option)
        return :ffmpeg if config.ffmpeg?
        return :mpg123 if config.mpg123?

        :sox if config.sox?
      end

      ##
      # Returns the appropriate channel flag for the decoder.
      #
      # @return [String, Integer] A flag for `mpg123` (`"-m"`) if mono, otherwise the channel count.
      def channels_flag
        return "-m" if mpg123? && mono?

        num_channels
      end

      ##
      # Checks if the current decoder is `mpg123`.
      #
      # @return [Boolean] `true` if the decoder is `mpg123`.
      def mpg123?
        set_decoder == :mpg123
      end
    end
  end
end
