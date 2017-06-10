import Dispatch
import Socket

let listenQueue = DispatchQueue.global(qos: .userInteractive)
let connectionQueue = DispatchQueue.global(qos: .userInitiated)

func handleConnection(_ request: ConnectionRequest) {
  guard let connection = request.accept(target: connectionQueue) else {
    log("failed to connect")
    return
  }

  log("new connection")

  connection.read()
    .flatMap(.concat, connection.write)
    .startWithCompleted {
      log("connection finished")
    }
}

let arguments = CommandLine.arguments.dropFirst()
let port = arguments.first.flatMap { Int($0) } ?? 8000

do {
  let socket = try Socket.listen(port: port, queue: listenQueue, handler: handleConnection)
  log("listening on port \(port)")
  dispatchMain()
} catch {
  let message = String(describing: error)
  log(message)
}
