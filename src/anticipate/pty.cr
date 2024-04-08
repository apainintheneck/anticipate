require "../lib/lib_pty"

module Anticipate
  class Pty
    class OpenError < StandardError; end

    def initialize
      # https://cs.opensource.google/go/go/+/refs/tags/go1.19.13:src/os/signal/internal/pty/pty.go
      # Use IO::FileDescriptor to open this after we're done calling functions on it
      primary_fd = LibPty.posix_openpt(LibC::O_RDWR)

      raise OpenError, "posix_openpt" if primary_fd.negative?
      raise OpenError, "grantpt" if LibPty.grantpt(primary_fd).negative?
      raise OpenError, "unlockpt" if LibPty.unlockpt(primary_fd).negative?

      secondary_name = LibPty.ptsname(primary_fd)
      raise OpenError, "ptsname" if secondary_name.null?

      secondary_name = String.new(secondary_name)
      # https://cs.opensource.google/go/go/+/refs/tags/go1.19.13:src/os/signal/signal_cgo_test.go
    end
  end
end
