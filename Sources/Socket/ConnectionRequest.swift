import Dispatch

public struct ConnectionRequest {
  var socket: Int32

  public func accept(target: DispatchQueue) throws -> Connection {
    return try Connection(socket: socket, target: target)
  }
}
