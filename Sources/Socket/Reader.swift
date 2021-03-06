import Foundation
import ReactiveSwift

final class Reader {
  private let reader: SignalProducer<Data, SocketError>

  func read() -> SignalProducer<Data, SocketError> {
    return reader
  }

  init(_ connection: Connection.Handle, capacity: Int, queue: DispatchQueue) {
    reader = SignalProducer { observer, disposable in
      let source = DispatchSource.makeReadSource(
        fileDescriptor: connection.fileDescriptor,
        queue: queue)

      source.setCancelHandler { _ = connection }
      disposable += source.cancel

      let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
      disposable += { buffer.deallocate(capacity: capacity) }

      var position = 0
      var lastRead = 0

      source.setEventHandler { [connection = connection.fileDescriptor] in
        if position == lastRead {
          position = 0
          let available = Int(source.data)
          let limit = min(capacity - position, available)
          lastRead = Darwin.read(connection, buffer + position, limit)
        }

        switch lastRead {
        case ..<0:
          // Data couldn't be read immediately, but we should try again
          guard errno != EAGAIN, errno != EINTR else { return }
          observer.send(error: .make("Socket read failed"))
        case 0:
          observer.sendCompleted()
        default:
          let data = Data(bytes: buffer + position, count: lastRead)

          position += lastRead

          observer.send(value: data)
        }
      }

      source.resume()
    }.replayLazily(upTo: .max)
  }
}
