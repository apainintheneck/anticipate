require "../src/anticipate"

Anticipate.spawn("stty") do |pty|
  pty.receive("...")
end

Anticipate.spawn("awk '{ exit(12); printf(\"%d. %s\", NF, $0) }'") do |pty|
  pty.send("hello world\nflatpack\n")
  pty.receive(/1/)
  pty.send("hello world")
  pty.receive(/world/)
  pty.send("goodbye cruel world")
  pty.receive("3. goodbye cruel world")
end
