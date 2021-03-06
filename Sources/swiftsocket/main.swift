import Dispatch
import Socket

let listenQueue = DispatchQueue.global(qos: .userInteractive)
let connectionQueue = DispatchQueue.global(qos: .userInitiated)

func handleConnection(_ request: ConnectionRequest) {
  let connection: Connection
  do {
    connection = try request.accept(target: connectionQueue)
    log("[connection] accepted")
  } catch {
    log("[connection] failed: \(error)")
    return
  }

  connection.read()
    .scanLines(separatedBy: .crlf)
    .flatMap(.concat, transform: connection.write)
    .on(failed: {
      log("[connection] terminated: \($0)")
    }, completed: {
      log("[connection] finished")
    })
    .start()
}

let arguments = CommandLine.arguments.dropFirst()
let port = arguments.first.flatMap { Int($0) } ?? 8000

let socket: Socket
do {
  socket = try Socket.listen(port: port, queue: listenQueue, handler: handleConnection)
  log("listening on port \(port)")
  dispatchMain()
} catch {
  let message = String(describing: error)
  fputs("fatal: \(message)\n", stderr)
  exit(1)
}
