import Darwin.C
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

  let length = 256
  let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: length)
  var current = 0
  var end = 0

  readSource.setEventHandler {
    if current == end {
      current = 0
      let available = Int(readSource.data)
      let limit = min(length - current, available)
      end = read(connection, buffer, limit)
    }

    switch end {
    case ..<0:
      log("\(label): read failed")
      readSource.cancel()
    case 0:
      log("\(label): finished")
      readSource.cancel()
    default:
      let step = write(connection, buffer + current, end - current)
      guard step >= 0 else {
        log("\(label): write failed")
        readSource.cancel()
        return
      }
      current += step
    }
  }

  readSource.setCancelHandler {
    buffer.deallocate(capacity: length)
    swiftsocket_close(connection)
  }

  readSource.resume()
}
