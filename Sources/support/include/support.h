/// Create a socket.
int swiftsocket_create(void);

/// Close a socket or connection.
int swiftsocket_close(int fd);

/// Bind a socket to listen on any IPV4 address, on a given port.
int swiftsocket_bind_any(int sock, int port);

/// Accept a connection on a socket and configure it for non-blocking IO.
int swiftsocket_accept(int sock);
