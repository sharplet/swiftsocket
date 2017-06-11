import Foundation
import ReactiveSwift

extension SignalProducer where Value == Data {
  func scanLines(separatedBy separator: LineSeparator) -> SignalProducer<Data, Error> {
    return SignalProducer { observer, disposable in
      var data = Data()
      var position = data.startIndex

      self.start { event in
        let chunk: Data

        switch event {
        case .failed, .interrupted:
          observer.action(event)
          return
        case .completed:
          observer.send(value: data)
          observer.sendCompleted()
          return
        case let .value(value):
          chunk = value
        }

        data.append(chunk)

        guard let lineSeparator = data.range(of: separator.bytes, in: position..<data.endIndex) else {
          position = data.index(before: data.endIndex)
          return
        }

        let line = data.startIndex..<lineSeparator.upperBound

        observer.send(value: data[line])

        data.removeSubrange(line)
        position = data.startIndex
      }
    }
  }
}
