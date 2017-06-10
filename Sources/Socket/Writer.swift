import Dispatch
import Foundation
import ReactiveSwift
import Result

final class Writer {
  private let source: DispatchSourceWrite
  private var writer: SignalProducer<Never, SocketError>!
  private var data = Data()

  func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    guard data.count > 0 else {
      source.cancel()
      return .empty
    }

    return writer.on(
      starting: { self.data.append(data) },
      started: source.resume
    )
  }

  init(_ connection: Int32, queue: DispatchQueue, completionHandler: @escaping () -> Void) {
    source = DispatchSource.makeWriteSource(
      fileDescriptor: connection,
      queue: queue)

    writer = SignalProducer<Never, SocketError> { [weak self, source] observer, lifetime in
      source.setCancelHandler(handler: completionHandler)
      lifetime.observeEnded(source.cancel)

      source.setEventHandler {
        guard let `self` = self else { source.cancel(); return }
        let data = self.data
        guard data.count > 0 else { source.suspend(); return }

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
          self.data.removeFirst(written)
        }
      }
    }.replayLazily(upTo: 1)
  }
}
