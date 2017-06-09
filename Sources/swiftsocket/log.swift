import Dispatch

func log(_ message: String) {
  DispatchQueue.main.async {
    print(message)
  }
}
