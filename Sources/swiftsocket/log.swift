import Darwin.C
import Dispatch

func log(_ message: String, to file: UnsafeMutablePointer<FILE> = stderr) {
  DispatchQueue.main.async {
    fputs("\(message)\n", stderr)
  }
}
