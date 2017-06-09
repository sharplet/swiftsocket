import support

func acceptConnection(_ sock: Int32) {
  guard case let connection = swiftsocket_accept(sock),
    connection >= 0
    else { log("failed to accept connection"); return }

  log("received a connection!")

  swiftsocket_close(connection)
}
