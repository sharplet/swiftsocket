import Dispatch

public struct ConnectionRequest {
  var socket: Int32

  public func accept(target: DispatchQueue) -> Connection? {
    return Connection(socket: socket, target: target)
  }
}
