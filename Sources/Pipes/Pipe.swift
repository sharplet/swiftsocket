import Dispatch

public final class Pipe<Element> {
  private var buffer: CircularBuffer<Element>
  private let source: DispatchSourceUserDataAdd

  public init(capacity: Int, queue: DispatchQueue, handler: @escaping (inout CircularBuffer<Element>) -> Void) {
    buffer = CircularBuffer(capacity: capacity)
    source = DispatchSource.makeUserDataAddSource(queue: queue)

    source.setEventHandler {
      handler(&self.buffer)
      self.source.add(data: self.availableData)
    }

    source.resume()
  }

  public func write(_ element: Element) {
    if buffer.write(element) {
      source.add(data: 1)
    }
  }

  private var availableData: UInt {
    return UInt(buffer.count)
  }
}
