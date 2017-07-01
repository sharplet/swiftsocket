import Pipes
import Quick
import Nimble

final class PipeSpec: QuickSpec {
  override func spec() {
    it("calls the event handler when data is available in the buffer") {
      var value: Int?

      let pipe = Pipe<Int>(capacity: 1, queue: .main) { buffer in
        value = buffer.readFirst()
      }

      pipe.write(123)

      expect(value).toEventually(equal(123))
    }

    it("calls the handler if data is still available after reading") {
      var values: [Int] = []

      let pipe = Pipe<Int>(capacity: 2, queue: .main) { buffer in
        if let value = buffer.readFirst() {
          values.append(value)
        }
      }

      pipe.write(1)
      expect(values).to(beEmpty())
      pipe.write(2)

      expect(values).toEventually(equal([1, 2]))
    }
  }
}
