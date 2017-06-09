import Dispatch
import ReactiveSwift
import Result
import support

enum Socket {
  static func listen(port: Int, queue: DispatchQueue) -> SignalProducer<Int32, NoError> {
    return SignalProducer { observer, lifetime in
      let sock = swiftsocket_create()
      guard sock >= 0 else { die("unable to create socket") }
      guard swiftsocket_bind_any(sock, Int32(port)) == 0 else { die("unable to bind socket \(sock)") }
      guard Darwin.listen(sock, 128) == 0 else { die("unable to listen on socket \(sock)") }

      let listener = DispatchSource.makeReadSource(fileDescriptor: sock, queue: queue)
      listener.setEventHandler { observer.send(value: sock) }

      lifetime.observeEnded(listener.cancel)

      listener.resume()
    }
  }
}

