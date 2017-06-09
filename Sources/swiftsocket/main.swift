import Dispatch
import support

func die(_ message: String = "") -> Never {
  perror(message)
  exit(1)
}

let arguments = CommandLine.arguments.dropFirst()
let port = arguments.first.flatMap { Int32($0) } ?? 8000

let sock = swiftsocket_create()
guard sock >= 0 else { die("unable to create socket") }
guard swiftsocket_bind_any(sock, port) == 0 else { die("unable to bind socket \(sock)") }
guard listen(sock, 128) == 0 else { die("unable to listen on socket \(sock)") }

log("listening on port \(port)")

let listenQueue = DispatchQueue.global(qos: .userInteractive)
let listener = DispatchSource.makeReadSource(fileDescriptor: sock, queue: listenQueue)
listener.setEventHandler { acceptConnection(sock) }
listener.resume()

dispatchMain()
