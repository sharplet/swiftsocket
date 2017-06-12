import Darwin.C
import Dispatch
import Foundation
import ReactiveSwift
import support

public final class Connection {
  final class Handle {
    let fileDescriptor: Int32

    init(_ connection: Int32) {
      fileDescriptor = connection
    }

    deinit {
      Darwin.close(fileDescriptor)
    }
  }

  private let reader: Reader
  private let writer: Writer

  init(socket: Int32, target: DispatchQueue) throws {
    let connection = swiftsocket_accept(socket)
    guard connection >= 0 else { throw SocketError.make("Unable to accept connection") }

    let handle = Handle(connection)

    let queue = DispatchQueue(label: "swiftsocket.connection.\(connection)", target: target)
    reader = Reader(handle, capacity: 256, queue: queue)
    writer = Writer(handle, queue: queue)
  }

  public func read() -> SignalProducer<Data, SocketError> {
    return reader.read()
  }

  public func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    return writer.write(data)
  }
}
