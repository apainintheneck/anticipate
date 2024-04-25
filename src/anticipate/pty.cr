require "../lib/lib_pty"

module Anticipate
  class Pty
    class OpenException < Exception
      def initialize(method : String, cause : Exception? = nil)
        message = "errno #{Errno.value}: failed when calling the #{method} method"
        super(message, cause)
      end
    end

    getter control_tty : IO::FileDescriptor
    getter process_tty : IO::FileDescriptor

    def initialize
      @control_tty = build_control_tty
      @process_tty = build_process_tty
    end

    def finalize
      process_tty.close if process_tty
      control_tty.finalize if control_tty
    end

    # https://cs.opensource.google/go/go/+/refs/tags/go1.19.13:src/os/signal/internal/pty/pty.go
    # https://cs.opensource.google/go/go/+/refs/tags/go1.19.13:src/os/signal/signal_cgo_test.go

    private def build_control_tty : IO::FileDescriptor
      control_tty_fd = LibPTY.posix_openpt(LibC::O_RDWR)

      raise OpenException.new("posix_openpt") if control_tty_fd.negative?
      raise OpenException.new("grantpt") if LibPTY.grantpt(control_tty_fd).negative?
      raise OpenException.new("unlockpt") if LibPTY.unlockpt(control_tty_fd).negative?

      IO::FileDescriptor.new(control_tty_fd, blocking: true).tap do |fd|
        fd.sync = true
      end
    end

    private def build_process_tty : IO::FileDescriptor
      process_tty_path = LibPTY.ptsname(control_tty.fd)
      raise OpenException.new("ptsname") if process_tty_path.null?

      process_tty_fd = LibC.open(process_tty_path, LibC::O_RDWR)
      IO::FileDescriptor.new(process_tty_fd).tap do |fd|
        # Broken until https://github.com/crystal-lang/crystal/pull/14529
        # Will likely be released in Crystal 1.13.x
        fd.raw!
      end
    end
  end
end
