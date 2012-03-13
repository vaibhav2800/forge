import socket

def singleinstance(port):
    '''Provides mutual exclusion by binding a socket. Returns success.

    Not destined for multithreaded use from the same process, but to be called
    once by each process to ensure it is the only instance running.
    '''

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.bind(('localhost', port))

        # prevent a successfully bound socket from being garbage collected,
        # otherwise a second process might be able to bind to the same port
        # while we are still running
        global __bound_sock
        __bound_sock = sock

        return True
    except socket.error:
        return False
