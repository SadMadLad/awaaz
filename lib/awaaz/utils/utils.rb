# frozen_string_literal: true

# This namespace contains utility classes and modules
# used internally by the Awaaz gem for audio processing.
#
# It requires and consolidates helper modules for resampling,
# sample manipulation, configuration, file reading, shell command
# building, and shell-based audio operations.
#
# @see Awaaz
# @since 0.1.0
#
# @example Accessing a utility class
#   Awaaz::Utils::Soundread.new("file.wav").read
#
require_relative "numo_arrays"
require_relative "resample"
require_relative "sound_config"
require_relative "soundread"
require_relative "shell_command_builder"
require_relative "via_shell"

# Awaaz gem
module Awaaz
  # The Utils module provides low-level helper components
  # for performing core audio-related operations in the Awaaz gem.
  #
  # These utilities are generally not intended for direct use by
  # consumers of the gem, but may be useful for advanced integrations.
  module Utils
  end

  def resample(...)
    Resample.read_and_resample(...)
  end
end
