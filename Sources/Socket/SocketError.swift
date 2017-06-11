import Darwin.C

public struct SocketError: Error {
  public var message: String
  public var errno: Int32

  static func make(_ message: String) -> SocketError {
    return SocketError(message: message, errno: Darwin.errno)
  }
}

extension SocketError: CustomStringConvertible {
  public var description: String {
    let underlying = String(cString: strerror(errno))
    return "\(message) - \(underlying)"
  }
}
