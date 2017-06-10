import Darwin.C
import Dispatch
import Foundation
import ReactiveSwift
import support

public final class Connection {
  private var connection: Int32!
  private let queue: DispatchQueue
  private var refcount = 0

  private var reader: SignalProducer<Data, SocketError>?

  init?(socket: Int32, target: DispatchQueue) {
    connection = swiftsocket_accept(socket)
    guard connection >= 0 else { return nil }
    queue = DispatchQueue(label: "swiftsocket.connection.\(connection)", target: target)
  }

  public func read() -> SignalProducer<Data, SocketError> {
    return reader ??= makeReader()
  }

  private func makeReader() -> SignalProducer<Data, SocketError> {
    guard let connection = connection else {
      preconditionFailure("tried to read from closed connection")
    }

    let capacity = 256

    let producer = SignalProducer<Data, SocketError> { observer, lifetime in
      self.queue.async { self.refcount += 1 }

      let source = DispatchSource.makeReadSource(
        fileDescriptor: connection,
        queue: self.queue)

      source.setCancelHandler(handler: self.cancel)
      lifetime.observeEnded(source.cancel)

      let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: 256)
      lifetime.observeEnded { buffer.deallocate(capacity: capacity) }

      var position = 0
      var lastRead = 0

      source.setEventHandler {
        if position == lastRead {
          position = 0
          let available = Int(source.data)
          let limit = min(capacity - position, available)
          lastRead = Darwin.read(connection, buffer, limit)
        }

        let data: Data

        switch lastRead {
        case ..<0:
          observer.send(error: .make("socket read failed"))
        case 0:
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
    }

    return producer.replayLazily(upTo: .max)
  }

  public func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    guard let connection = connection else {
      preconditionFailure("tried to write to closed connection")
    }

    return SignalProducer { observer, lifetime in
      self.queue.async { self.refcount += 1 }

      let source = DispatchSource.makeWriteSource(
        fileDescriptor: connection,
        queue: self.queue)

      source.setCancelHandler(handler: self.cancel)
      lifetime.observeEnded(source.cancel)

      var data = data

      source.setEventHandler {
        guard data.count > 0 else {
          observer.sendCompleted()
          return
        }

        let available = Int(source.data)
        let limit = min(data.count, available)
        let written = data.withUnsafeBytes { buffer in
          Darwin.write(connection, buffer, limit)
        }

        switch written {
        case ..<0:
          observer.send(error: .make("socket write failed"))
        case 0:
          observer.sendCompleted()
        default:
          data.removeFirst(written)
        }
      }

      source.resume()
    }
  }

  private func cancel() {
    refcount -= 1
    guard refcount == 0 else { return }
    close()
  }

  public func close() {
    guard connection != nil else { return }
    Darwin.close(connection)
    connection = nil
  }

  deinit {
    close()
  }
}
