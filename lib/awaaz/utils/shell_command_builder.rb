# frozen_string_literal: true

module Awaaz
  module Utils
    class ShellCommandBuilder
      def initialize(base = nil)
        @args = [base.to_s]
      end

      def add_arg(arg)
        @args << arg.to_s.strip

        self
      end

      alias add_flag add_arg

      def add_option(option, value, with_colon: false)
        @args << "#{option}#{with_colon ? ":" : " "}#{value}"

        self
      end

      def add_multiple_args(args_array)
        args_array.each do |shell_args|
          arg_type, args = shell_args
          arg_type = arg_type.to_sym

          %i[arg flag].include?(arg_type) ? add_arg(*args) : add_option(*args)
        end

        self
      end

      def command
        @args.join(" ")
      end
    end
  end
end
