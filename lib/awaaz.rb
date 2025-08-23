# frozen_string_literal: true

##
# Main namespace for the Awaaz gem.
#
# The Awaaz gem provides audio decoding utilities and related tools for working
# with various audio formats. It uses FFI bindings and Numo::NArray for numerical
# processing and includes multiple decoders, utilities, and configuration options.
#
# @see Awaaz::Decoders
# @see Awaaz::Utils
# @see Awaaz::Config
# @see Awaaz::Features
# @see Awaaz::Properties
require "ffi"
require "numo/narray"
require "numo/pocketfft"

require_relative "awaaz/errors"
require_relative "awaaz/extensions/extensions"
require_relative "awaaz/utils/utils"
require_relative "awaaz/version"

require_relative "awaaz/config"
require_relative "awaaz/decoders/decoders"
require_relative "awaaz/features"
require_relative "awaaz/properties"

module Awaaz
  extend Features
  extend Properties
end
