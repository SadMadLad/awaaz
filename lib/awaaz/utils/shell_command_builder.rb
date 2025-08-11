# frozen_string_literal: true

module Awaaz
  module Utils
    ##
    # A utility class to construct shell commands in a safe and composable way.
    #
    # This class supports chaining methods to add arguments, flags, and options,
    # and finally output the full shell command string.
    #
    # @example Build a simple FFmpeg command
    #   cmd = ShellCommandBuilder.new(:ffmpeg)
    #            .add_flag("-nostdin")
    #            .add_option("-i", "input.mp3")
    #            .add_option("-ar", 44100)
    #            .command
    #   # => "ffmpeg -nostdin -i input.mp3 -ar 44100"
    #
    class ShellCommandBuilder
      ##
      # Initializes a new shell command builder.
      #
      # @param base [String, Symbol, nil] The base command (e.g., `:ffmpeg` or `"ls"`).
      #
      def initialize(base = nil)
        @args = [base.to_s]
      end

      ##
      # Adds a positional argument to the command.
      #
      # @param arg [String, Symbol, Numeric] The argument to add.
      # @return [ShellCommandBuilder] self, for chaining.
      #
      def add_arg(arg)
        @args << arg.to_s.strip
        self
      end

      ##
      # Alias for {#add_arg}, used for flags.
      #
      # @see #add_arg
      alias add_flag add_arg

      ##
      # Adds an option with a value to the command.
      #
      # @param option [String, Symbol] The option flag (e.g., `-i`).
      # @param value [String, Symbol, Numeric] The value for the option.
      # @param with_colon [Boolean] Whether to separate the option and value with a colon (`:`)
      #   instead of a space.
      # @return [ShellCommandBuilder] self, for chaining.
      #
      # @example Space-separated
      #   builder.add_option("-i", "file.mp3")
      #   # => "-i file.mp3"
      #
      # @example Colon-separated
      #   builder.add_option("--volume", 10, with_colon: true)
      #   # => "--volume:10"
      #
      def add_option(option, value, with_colon: false)
        @args << "#{option}#{with_colon ? ":" : " "}#{value}"
        self
      end

      ##
      # Adds multiple arguments or options at once.
      #
      # @param args_array [Array<Array>] An array of argument definitions.
      #   Each element should be `[type, args]` where:
      #   - `type` is `:arg` or `:flag` for positional arguments/flags
      #   - otherwise, treated as an option for {#add_option}
      #
      # @return [ShellCommandBuilder] self, for chaining.
      #
      # @example Adding multiple
      #   builder.add_multiple_args([
      #     [:flag, ["-q"]],
      #     [:option, ["-i", "file.mp3"]],
      #     [:arg, ["extra"]]
      #   ])
      #
      def add_multiple_args(args_array)
        args_array.each do |shell_args|
          arg_type, args = shell_args
          arg_type = arg_type.to_sym
          %i[arg flag].include?(arg_type) ? add_arg(*args) : add_option(*args)
        end
        self
      end

      ##
      # Builds and returns the complete shell command string.
      #
      # @return [String] The constructed command.
      #
      def command
        @args.join(" ")
      end
    end
  end
end
