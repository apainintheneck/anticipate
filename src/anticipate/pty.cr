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
    getter process_tty : File

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

    private def build_process_tty : File
      process_tty_path = LibPTY.ptsname(control_tty.fd)
      raise OpenException.new("ptsname") if process_tty_path.null?

      process_tty_path = String.new(process_tty_path)
      File.open(process_tty_path, "w+")
    end
  end
end
