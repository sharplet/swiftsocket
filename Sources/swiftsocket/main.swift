import Dispatch

let arguments = CommandLine.arguments.dropFirst()
let port = arguments.first.flatMap { Int($0) } ?? 8000

let socket = Socket.listen(port: port, queue: .global(qos: .userInteractive))

socket.startWithValues { socket in
  acceptConnection(socket, target: .global(qos: .userInitiated))
}

log("listening on port \(port)")

dispatchMain()
