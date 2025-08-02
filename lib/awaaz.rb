# frozen_string_literal: true

require "numo/narray"

require_relative "awaaz/errors"

require_relative "awaaz/version"
require_relative "awaaz/config"
require_relative "awaaz/decoders/decoders"

require "pry"

module Awaaz
end

p Awaaz::Decoders::WavefileDecoder.new("/home/saad/Downloads/sample-wav.wav", decoder: :ffmpeg).load
