public struct CircularBuffer<Element> {
  private let buffer: Buffer

  public init(capacity: Int) {
    buffer = Buffer.create(minimumCapacity: capacity) { _ in
      Header(startIndex: 0, count: 0)
    } as! Buffer
  }

  public mutating func write(_ elements: [Element]) -> Int? {
    let capacity = buffer.capacity
    return buffer.modify { header, buffer in
      let available = capacity - header.count
      let count = Swift.min(available, elements.count)
      defer { header.count += count }
      (buffer + header.count).assign(from: elements, count: count)
      return count
    }
  }
}

private extension CircularBuffer {
  struct Header {
    var startIndex: Int
    var count: Int
  }

  final class Buffer: ManagedBuffer<Header, Element> {
    func modify<Result>(_ body: (inout Header, UnsafeMutablePointer<Element>) -> Result) -> Result {
      return withUnsafeMutablePointers { header, elements in
        return body(&header.pointee, elements)
      }
    }

    func position(for offset: Int) -> Int {
      let position = header.startIndex + offset
      if position < capacity {
        return position
      } else {
        return capacity - position
      }
    }
  }
}

extension CircularBuffer: Collection {
  public struct Index: Comparable {
    fileprivate var offset: Int

    public static func == (lhs: Index, rhs: Index) -> Bool {
      return lhs.offset == rhs.offset
    }

    public static func < (lhs: Index, rhs: Index) -> Bool {
      return lhs.offset < rhs.offset
    }
  }

  public var startIndex: Index {
    return Index(offset: 0)
  }

  public var endIndex: Index {
    return Index(offset: buffer.header.count)
  }

  public func index(after i: Index) -> Index {
    return Index(offset: i.offset + 1)
  }

  public subscript(index: Index) -> Element {
    let position = buffer.position(for: index.offset)
    return buffer.withUnsafeMutablePointerToElements { $0[position] }
  }
}
