# frozen_string_literal: true

require "ffi"

module Extensions
  module Soundfile
    extend FFI::Library

    ffi_lib "sndfile"

    SFM_READ = 0x10

    class SF_INFO < FFI::Struct
      layout :frames, :long_long,
             :samplerate, :int,
             :channels, :int,
             :format, :int,
             :sections, :int,
             :seekable, :int
    end

    attach_function :sf_open, %i[string int pointer], :pointer
    attach_function :sf_readf_float, %i[pointer pointer long_long], :long_long
    attach_function :sf_close, [:pointer], :int
  end
end
