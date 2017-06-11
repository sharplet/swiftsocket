import Foundation

enum LineSeparator {
  case crlf
  case lf

  var bytes: Data {
    switch self {
    case .crlf:
      return Data.crlf
    case .lf:
      return Data.lf
    }
  }
}

private extension UInt8 {
  static let cr = UInt8(ascii: "\r")
  static let lf = UInt8(ascii: "\n")
}

private extension Data {
  static let crlf = Data(bytes: [.cr, .lf])
  static let lf = Data(bytes: [.lf])
}
