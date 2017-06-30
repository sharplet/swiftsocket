import Dispatch
import Foundation
import ReactiveSwift
import Result

final class Writer {
  private var buffer = Buffer()
  private let source: DispatchSourceWrite

  func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    return SignalProducer { observer, disposable in
      guard data.count > 0 else {
        observer.sendCompleted()
        return
      }

      disposable += self.buffer
        .write(data)
        .start(observer)

      disposable += { _ = self }
    }
  }

  init(_ connection: Connection.Handle, queue: DispatchQueue) {
    source = DispatchSource.makeWriteSource(
      fileDescriptor: connection.fileDescriptor,
      queue: queue)

    source.setCancelHandler { _ = connection }

    source.setEventHandler { [buffer, source] in
      guard buffer.hasData else { return }
      buffer.write(upTo: Int(source.data), on: connection.fileDescriptor)
    }

    source.resume()
  }

  deinit {
    source.cancel()
  }
}

private final class Buffer {
  enum WriteResult {
    case partial
    case complete
    case failed(SocketError)
  }

  private let (events, observer) = Signal<(Int, WriteResult), NoError>.pipe()
  private var counter = 0
  private var queue: [(id: Int, data: Data)] = []

  var hasData: Bool {
    return queue.count > 0
  }

  func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    return SignalProducer { observer, disposable in
      let id = self.counter
      self.counter += 1
      self.queue.append((id, data))

      disposable += self.events.observe { event in
        switch event {
        case let .value((eventId, .complete)) where eventId == id:
          fallthrough
        case .completed:
          observer.sendCompleted()

        case let .value((eventId, .failed(error))) where eventId == id:
          observer.send(error: error)

        case .value:
          break

        case .interrupted:
          observer.sendInterrupted()
        }
      }
    }
  }

  func write(upTo available: Int, on fileDescriptor: Int32) {
    guard queue.count > 0 else { preconditionFailure("Tried to write with no enqueued data") }

    let id = queue[0].id
    let count = queue[0].data.count
    let limit = min(available, count)

    let written = queue[0].data.withUnsafeBytes { buffer in
      Darwin.write(fileDescriptor, buffer, limit)
    }

    switch written {
    case ..<0:
      // Data couldn't be written immediately, but we should try again
      guard errno != EAGAIN, errno != EINTR else { return }
      observer.send(value: (id, .failed(.make("Socket write failed"))))
    default:
      if written == count {
        queue.removeFirst()
        observer.send(value: (id, .complete))
      } else {
        queue[0].data.removeFirst(written)
        observer.send(value: (id, .partial))
      }
    }
  }
}
