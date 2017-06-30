import Pipes
import Quick
import Nimble
import XCTest

final class CircularBufferTests: QuickSpec {
  override func spec() {
    describe("write") {
      it("can write less than the buffer capacity") {
        var buffer = CircularBuffer<Int>(capacity: 5)
        expect(buffer.write([1, 2, 3])) == 3
        expect(Array(buffer)) == [1, 2, 3]
      }

      it("writes as much as possible up to the capacity") {
        var buffer = CircularBuffer<Int>(capacity: 2)
        expect(buffer.write([1, 2, 3])) == 2
        expect(Array(buffer)) == [1, 2]
      }
    }
  }
}
