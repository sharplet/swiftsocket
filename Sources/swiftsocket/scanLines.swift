import Foundation
import ReactiveSwift

extension SignalProducer where Value == Data {
  func scanLines(separatedBy separator: LineSeparator) -> SignalProducer<Data, Error> {
    return SignalProducer { observer, disposable in
      var data: Data!
      var position: Data.Index!

      self.start { event in
        let chunk: Data

        switch event {
        case .failed, .interrupted:
          observer.action(event)
          return
        case .completed:
          if data != nil {
            observer.send(value: data)
          }
          observer.sendCompleted()
          return
        case let .value(value):
          guard value.count > 0 else { return }
          chunk = value
        }

        if data == nil {
          data = chunk
          position = data.startIndex
        } else {
          data.append(chunk)
        }

        while data.count > 0 {
          guard let lineSeparator = data.range(of: separator.bytes, in: position..<data.endIndex) else {
            position = data.index(before: data.endIndex)
            break
          }

          let line = data.startIndex..<lineSeparator.upperBound

          observer.send(value: data[line])

          data.removeSubrange(line)
          position = data.startIndex
        }
      }
    }
  }
}
