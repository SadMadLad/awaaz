# frozen_string_literal: true

module Awaaz
  ##
  # The Extensions module is a namespace for FFI-based bindings to external libraries.
  module Extensions
    ##
    # The Soundfile module provides Ruby bindings to the `libsndfile` C library
    # using the FFI (Foreign Function Interface).
    #
    # It allows reading audio file metadata and sample data directly from Ruby.
    #
    # @see http://www.mega-nerd.com/libsndfile/ Official libsndfile documentation
    module Soundfile
      extend FFI::Library

      # Load the libsndfile shared library
      ffi_lib "sndfile"

      ##
      # Open mode for reading sound files.
      # @return [Integer] Bitmask flag for read mode.
      SFM_READ = 0x10

      # rubocop:disable Naming/ClassAndModuleCamelCase

      ##
      # Structure containing metadata about an audio file.
      #
      # Mirrors the C struct `SF_INFO` from libsndfile.
      #
      # @!attribute [rw] frames
      #   @return [Integer] Total number of frames in the file.
      # @!attribute [rw] samplerate
      #   @return [Integer] Sample rate of the audio file (Hz).
      # @!attribute [rw] channels
      #   @return [Integer] Number of audio channels.
      # @!attribute [rw] format
      #   @return [Integer] Format identifier of the audio file.
      # @!attribute [rw] sections
      #   @return [Integer] Number of sections in the file.
      # @!attribute [rw] seekable
      #   @return [Integer] Whether the file is seekable (1) or not (0).
      class SF_INFO < FFI::Struct
        layout :frames, :long_long,
               :samplerate, :int,
               :channels,   :int,
               :format,     :int,
               :sections,   :int,
               :seekable,   :int
      end

      # rubocop:enable Naming/ClassAndModuleCamelCase

      ##
      # Opens an audio file and returns a pointer to the file handle.
      #
      # @param path [String] Path to the audio file.
      # @param mode [Integer] Mode flags (e.g., {SFM_READ} for reading).
      # @param sf_info [FFI::Pointer] Pointer to an {SF_INFO} struct to store metadata.
      # @return [FFI::Pointer] Pointer to the opened file handle.
      # @see http://www.mega-nerd.com/libsndfile/api.html#open
      attach_function :sf_open, %i[string int pointer], :pointer

      ##
      # Reads floating-point audio frames from an open file.
      #
      # @param sndfile [FFI::Pointer] Pointer to the open sound file.
      # @param buffer [FFI::Pointer] Buffer to store the read samples.
      # @param frames [Integer] Number of frames to read.
      # @return [Integer] Number of frames actually read.
      attach_function :sf_readf_float, %i[pointer pointer long_long], :long_long

      ##
      # Closes an open audio file.
      #
      # @param sndfile [FFI::Pointer] Pointer to the open sound file.
      # @return [Integer] Zero on success, non-zero on error.
      attach_function :sf_close, [:pointer], :int
    end
  end
end
