import Dispatch
import Foundation
import ReactiveSwift
import Result
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
    .scanLines(separatedBy: .crlf)
    .flatMap(.latest, connection.write)
    .on(failed: {
      log("connection terminated: \($0.message)")
    }, completed: {
      log("connection finished")
    })
    .start()
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
