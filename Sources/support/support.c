#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>

int swiftsocket_create(void)
{
  return socket(PF_INET, SOCK_STREAM, 0);
}

int swiftsocket_close(int fd)
{
  return close(fd);
}

int swiftsocket_bind_any(int sock, int port)
{
  int result, yes = 1;
  struct sockaddr_in addr = {
    sizeof(addr),
    AF_INET,
    htons(port),
    { INADDR_ANY },
    { 0 },
  };

  result = setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
  if (result != 0)
    return result;

  result = bind(sock, (void *)&addr, sizeof(addr));

  return result;
}

int swiftsocket_accept(int sock)
{
  int connection, result;
  struct sockaddr addr;
  socklen_t length = sizeof(addr);

  if ((connection = accept(sock, &addr, &length)) < 0)
    return connection;

  if ((result = fcntl(connection, F_SETFL, fcntl(sock, F_GETFL, 0) | O_NONBLOCK)) != 0)
    return -1;

  return connection;
}
