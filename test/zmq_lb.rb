require "em-zeromq"

zmq = EM::ZeroMQ::Context.new(1)

EM.run {
  req = zmq.socket(ZMQ::REQ)
  req.on(:message) { |*parts|
    p [:parts, parts.map(&:copy_out_string)]
  }

  5.times do |t|
    rep = zmq.socket(ZMQ::REP)
    fd = "ipc:///tmp/rep#{t}"
    rep.bind(fd)
    rep.on(:message) { |*parts|
      p [:parts, parts.map(&:copy_out_string)]
      rep.send_msg("hello from req #{t}")
    }
    req.connect(fd)
  end

  i = 0
  EM.add_periodic_timer(1) {
    puts "Sending 2-part message"
    i += 1
    req.send_msg("hello #{i}", "second part")
  }
}


__END__

Sending 2-part message
[:parts, ["hello 1", "second part"]]
[:parts, ["hello from req 0"]]
Sending 2-part message
[:parts, ["hello 2", "second part"]]
[:parts, ["hello from req 1"]]
Sending 2-part message
[:parts, ["hello 3", "second part"]]
[:parts, ["hello from req 2"]]
Sending 2-part message
[:parts, ["hello 4", "second part"]]
[:parts, ["hello from req 3"]]
Sending 2-part message
[:parts, ["hello 5", "second part"]]
[:parts, ["hello from req 4"]]
Sending 2-part message
[:parts, ["hello 6", "second part"]]
[:parts, ["hello from req 0"]]
Sending 2-part message
[:parts, ["hello 7", "second part"]]
[:parts, ["hello from req 1"]]
Sending 2-part message
[:parts, ["hello 8", "second part"]]
[:parts, ["hello from req 2"]]
Sending 2-part message
[:parts, ["hello 9", "second part"]]
[:parts, ["hello from req 3"]]
Sending 2-part message
[:parts, ["hello 10", "second part"]]
[:parts, ["hello from req 4"]]