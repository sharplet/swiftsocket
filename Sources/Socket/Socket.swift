import Dispatch
import support

public final class Socket {
  private let listener: DispatchSourceRead

  private init(_ source: DispatchSourceRead) {
    listener = source
  }

  public func cancel() {
    listener.cancel()
  }

  public static func listen(port: Int, queue: DispatchQueue, handler handle: @escaping (ConnectionRequest) -> Void) throws -> Socket {
    let socket = swiftsocket_create()

    guard socket >= 0 else {
      throw SocketError.make("Unable to create socket")
    }

    guard swiftsocket_bind_any(socket, Int32(port)) == 0 else {
      throw SocketError.make("Unable to bind socket")
    }

    guard Darwin.listen(socket, 128) == 0 else {
      throw SocketError.make("Unable to listen on socket")
    }

    let listener = DispatchSource.makeReadSource(fileDescriptor: socket, queue: queue)

    listener.setEventHandler {
      let request = ConnectionRequest(socket: socket)
      handle(request)
    }

    defer { listener.resume() }

    return Socket(listener)
  }
}
