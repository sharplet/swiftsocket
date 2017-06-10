import Darwin.C
import Dispatch
import Foundation
import ReactiveSwift
import support

public final class Connection {
  private final class Handle {
    var fileDescriptor: Int32

    init(_ connection: Int32) {
      fileDescriptor = connection
    }

    deinit {
      Darwin.close(fileDescriptor)
    }
  }

  private let handle: Unmanaged<Handle>
  private let reader: Reader
  private let writer: Writer

  init?(socket: Int32, target: DispatchQueue) {
    let connection = swiftsocket_accept(socket)
    guard connection >= 0 else { return nil }

    handle = Unmanaged
      .passRetained(Handle(connection))
      .retain()

    let queue = DispatchQueue(label: "swiftsocket.connection.\(connection)", target: target)
    reader = Reader(connection, capacity: 256, queue: queue, completionHandler: handle.release)
    writer = Writer(connection, queue: queue, completionHandler: handle.release)
  }

  public func read() -> SignalProducer<Data, SocketError> {
    return reader.read()
  }

  public func write(_ data: Data) -> SignalProducer<Never, SocketError> {
    return writer.write(data)
  }
}
