import Dispatch
import support

func acceptConnection(_ sock: Int32, target: DispatchQueue) {
  guard case let connection = swiftsocket_accept(sock),
    connection >= 0
    else { log("failed to accept connection"); return }

  let label = "swiftsocket.connection.\(connection)"

  // Connection queue is serial with respect to the current connection,
  // but targets the global read queue, and is such concurrent with
  // respect to any other active connections.
  let connectionQueue = DispatchQueue(label: label, target: target)

  let readSource = DispatchSource.makeReadSource(
    fileDescriptor: connection,
    queue: connectionQueue)

  readSource.setEventHandler {
    log("read event on \(label)")
    readSource.cancel()
  }

  readSource.setCancelHandler {
    swiftsocket_close(connection)
  }

  readSource.resume()
}
