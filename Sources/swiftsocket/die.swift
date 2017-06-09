import Darwin.C

func die(_ message: String = "") -> Never {
  perror(message)
  exit(1)
}
