require "ffi"

module Extensions
  module Samplerate
    extend FFI::Library
    ffi_lib 'samplerate'

    class SRC_DATA < FFI::Struct
      layout :data_in,     :pointer,
            :data_out,    :pointer,
            :input_frames,  :long,
            :output_frames, :long,
            :input_frames_used, :long,
            :output_frames_gen, :long,
            :end_of_input, :int,
            :src_ratio,    :double
    end

    attach_function :src_simple, [SRC_DATA.by_ref, :int, :int], :int
    attach_function :src_strerror, [:int], :string

    SRC_SINC_BEST_QUALITY	= 0
    SRC_SINC_MEDIUM_QUALITY	= 1
    SRC_SINC_FASTEST = 2
    SRC_ZERO_ORDER_HOLD	= 3
    SRC_LINEAR = 4

    class << self
      def resample_option(option)
        case option
        when 0, :sinc_best_quality then SRC_SINC_BEST_QUALITY
        when 1, :sinc_medium_quality then SRC_SINC_MEDIUM_QUALITY
        when 2, :sinc_fastest then SRC_SINC_FASTEST
        when 3, :zero_order_hold then SRC_ZERO_ORDER_HOLD
        when 4, :linear then SRC_LINEAR
        else raise ArgumentError, "Not found"
        end
      end
    end
  end
end
