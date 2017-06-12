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

      if buffer.isEmpty {
        defer { source.resume() }
      }

      buffer.append(data)

      let disposable = events.observe { event in
        switch event {
        case .value(.writeFinished), .completed:
          observer.sendCompleted()
        case let .value(.writeFailed(error)):
          observer.send(error: error)
        case .interrupted:
          observer.sendInterrupted()
        case .failed:
          break
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
      assert(buffer.count > 0)

      let available = Int(source.data)
      let limit = min(available, buffer.count)

      let result = buffer.write(upTo: limit, on: connection.fileDescriptor)

      switch result {
      case let .failed(error):
        observer.send(value: .writeFailed(error))
      case .bytesRemaining:
        break
      case .complete:
        source.suspend()
        observer.send(value: .writeFinished)
      case .finalized:
        source.cancel()
        observer.sendCompleted()
      }
    }
  }

  deinit {
    if buffer.isEmpty {
      source.cancel()
      source.resume()
    } else {
      buffer.finalize()
    }
  }
}

private final class Buffer {
  enum WriteResult {
    case bytesRemaining
    case complete
    case finalized
    case failed(SocketError)
  }

  private var data = Data()
  private var shouldFinalize = false

  var count: Int {
    return data.count
  }

  var isEmpty: Bool {
    return data.isEmpty
  }

  func append(_ data: Data) {
    self.data.append(data)
  }

  func finalize() {
    precondition(shouldFinalize == false, "buffer finalized twice")
    shouldFinalize = true
  }

  func write(upTo count: Int, on fileDescriptor: Int32) -> WriteResult {
    let written = data.withUnsafeBytes { buffer in
      Darwin.write(fileDescriptor, buffer, count)
    }

    switch written {
    case ..<0:
      return .failed(.make("Socket write failed"))
    default:
      if written > 0 {
        data.removeFirst(written)
      }

      if isEmpty {
        if shouldFinalize {
          return .finalized
        } else {
          return .complete
        }
      } else {
        return .bytesRemaining
      }
    }
  }
}
