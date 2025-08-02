# frozen_string_literal: true

require "numo/narray"

require_relative "awaaz/errors"

require_relative "awaaz/version"
require_relative "awaaz/config"
require_relative "awaaz/decoders/decoders"

require "pry"

module Awaaz
end

x = Awaaz::Decoders::WavefileDecoder.new("/home/saad/Downloads/sample-wav.wav", decoder: :ffmpeg).load
y = Awaaz::Decoders::Mp3Decoder.new("/home/saad/Downloads/\"nokia tune\".mp3", decoder: :ffmpeg).load
binding.pry
