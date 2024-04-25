require "./pty"

require "process"

module Anticipate
  class Runner
    class StopException < Exception
      def initialize(
        @message : String? = nil,
        @cause : Exception? = nil,
        file : String? = nil,
        line : Int? = nil
      )
        if file && line && (@message || @cause)
          @message = "#{file}:#{line}: #{@message || @cause.try(&.message)}"
        end
      end
    end

    getter closed = false

    @command : String
    @pty : Pty
    @process : Process

    def initialize(@command : String, @read_write_timeout = Time::Span.new(seconds: 10))
      @pty = Pty.new

      command_args = Process.parse_arguments(command)
      command_program = command_args.shift
      executable_path = Process.find_executable(command_program)
      raise StopException.new("missing executable: #{command_program}") if executable_path.nil?

      @process = Process.new(
        command: executable_path,
        args: command_args,
        input: @pty.process_tty,
        output: @pty.process_tty,
        error: @pty.process_tty
      )
    end

    def send(message : String, file = __FILE__, line = __LINE__)
      stoppable(file, line) do
        @pty.control_tty.print message
      end
    end

    def receive(message : String | Regex, file = __FILE__, line = __LINE__)
      stoppable(file, line) do
        response = IO::Memory.new(capacity: 1024).tap do |buffer|
          bytes = Bytes.new(128)
          loop do
            bytes_read = @pty.control_tty.read bytes
            break if bytes_read.zero?

            if bytes_read == bytes.size
              buffer.write bytes
            else
              buffer.write bytes[0...bytes_read]
              break
            end
          end
        end.to_s

        next if case message
        when String
          message == response
        when Regex
          message.matches? response
        end

        raise StopException.new(<<-ERROR)
          Unexpected response error for script `#{@command}`.

          received: #{response.inspect}
          expected: #{message.inspect}
        ERROR
      end
    end

    def close
      return if closed

      @process.terminate
      @closed = true
    end

    private def stoppable(file : String, line : Int)
      raise StopException.new("pty has already been closed", file: file, line: line) if closed

      yield
    rescue ex
      close

      case ex
      when StopException
        raise ex
      else
        raise StopException.new(cause: ex, file: file, line: line)
      end
    end
  end
end
