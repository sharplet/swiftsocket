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

      it("supports writing a single element") {
        var buffer = CircularBuffer<Int>(capacity: 1)
        expect(buffer.write(123)) == true
        expect(Array(buffer)) == [123]
      }
    }

    describe("readFirst()") {
      it("removes the first element from the buffer") {
        var buffer = CircularBuffer<Int>(capacity: 3)
        _ = buffer.write([1, 2])
        expect(buffer.readFirst()) == 1
        expect(Array(buffer)) == [2]
      }

      it("returns nil if the buffer is empty") {
        var buffer = CircularBuffer<Int>(capacity: 1)
        expect(buffer.readFirst()).to(beNil())
      }
    }
  }
}
