import Foundation
import ReactiveSwift

final class Reader {
  private let reader: SignalProducer<Data, SocketError>

  func read() -> SignalProducer<Data, SocketError> {
    return reader
  }

  init(_ connection: Connection.Handle, capacity: Int, queue: DispatchQueue) {
    reader = SignalProducer { observer, lifetime in
      let source = DispatchSource.makeReadSource(
        fileDescriptor: connection.fileDescriptor,
        queue: queue)

      source.setCancelHandler { _ = connection }
      lifetime.observeEnded(source.cancel)

      let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: 256)
      lifetime.observeEnded { buffer.deallocate(capacity: capacity) }

      var position = 0
      var lastRead = 0

      source.setEventHandler { [connection = connection.fileDescriptor] in
        if position == lastRead {
          position = 0
          let available = Int(source.data)
          let limit = min(capacity - position, available)
          lastRead = Darwin.read(connection, buffer, limit)
        }

        switch lastRead {
        case ..<0:
          observer.send(error: .make("socket read failed"))
        case 0:
          observer.send(value: Data())
          observer.sendCompleted()
        default:
          let data = Data(
            bytesNoCopy: buffer + position,
            count: lastRead - position,
            deallocator: .none)

          position += lastRead

          observer.send(value: data)
        }
      }

      source.resume()
    }.replayLazily(upTo: .max)
  }
}