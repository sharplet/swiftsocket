import Dispatch
import Foundation
import ReactiveSwift
import Result

final class Writer {
  private enum Event {
    case writeFinished
    case writeFailed(SocketError)
  }

  private var buffer = Buffer()
  private let source: DispatchSourceWrite
  private let (events, observer) = Signal<Event, NoError>.pipe()

  func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    return SignalProducer { [buffer, events, source] observer, lifetime in
      guard data.count > 0 else {
        source.cancel()
        source.resume()
        observer.sendCompleted()
        return
      }

      buffer.append(data)
      defer { source.resume() }

      let disposable = events.observeValues { event in
        switch event {
        case .writeFinished:
          observer.sendCompleted()
        case .writeFailed(let error):
          observer.send(error: error)
        }
      }

      lifetime.observeEnded { disposable?.dispose() }
    }
  }

  init(_ connection: Connection.Handle, queue: DispatchQueue) {
    source = DispatchSource.makeWriteSource(
      fileDescriptor: connection.fileDescriptor,
      queue: queue)

    source.setCancelHandler { _ = connection }

    source.setEventHandler { [buffer, observer, source] in
      guard buffer.count > 0 else {
        source.suspend()
        observer.send(value: .writeFinished)
        return
      }

      let available = Int(source.data)
      let limit = min(available, buffer.count)
      let written = buffer.withUnsafeBytes { buffer in
        Darwin.write(connection.fileDescriptor, buffer, limit)
      }

      switch written {
      case ..<0:
        observer.send(value: .writeFailed(.make("socket write failed")))
      default:
        buffer.removeFirst(written)
      }
    }

    source.resume()
  }
}

private final class Buffer {
  var data = Data()

  var count: Int {
    return data.count
  }

  func append(_ data: Data) {
    self.data.append(data)
  }

  func removeFirst(_ n: Int) {
    data.removeFirst(n)
  }

  func withUnsafeBytes<Result>(_ body: (UnsafePointer<Int8>) throws -> Result) rethrows -> Result {
    return try data.withUnsafeBytes(body)
  }
}
