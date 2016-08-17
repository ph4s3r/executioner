require 'socket'               # Get sockets from stdlib
require 'benchmark'


PORT = 12078
DATAPORT = 29629

$/ = "EOC"
#	  This above is Input record separator, newline by default. Works like awk’s RS variable. If it is set to nil,
#   A whole file will be read at once. gets, readline, etc. take the input record separator as an optional argument. See also $-0.

printf "cmdr$: TCP server listening on %d port\n", PORT

#This server is actually a controller
#First feature it knows is to shut down the actual connection - when
#Second feature is to run arbitrary command on windows shell and return the values in file


def sendfile(command)

  filesenderserver = TCPServer.open(DATAPORT)
  #open one new server on the same port in a new child process, and client should connect

  ####NONBLOCKING SOCKET
=begin
  filesenderserver = Socket.new(AF_INET, SOCK_STREAM, 0)
  sockaddr = Socket.sockaddr_in(DATAPORT, HOST)
  filesenderserver.bind(sockaddr)
  filesenderserver.listen(5)

  begin
    client_socket, client_sockaddr = filesenderserver.accept_nonblock
  rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EINTR, Errno::EWOULDBLOCK
    IO.select([filesenderserver])
    retry
  end
=end

  loop {
        client = filesenderserver.accept
        #here open a file from cmd, then send
        printf "cmdr$: data connection established with an execution client on port %d, id: %d \n", DATAPORT, client.__id__
        #open the file to read from it to the memory
        mcmd = command.split(" ", 3)
        file = open(mcmd[1], "rb")
        file_size = File.size(file)
        printf "cmdr$: file ready for sending: %s size: %i B\n", mcmd[1].to_s, file_size
        #filesenderserver.puts "filesize:" + file_size.to_s
        fileContent = file.read
        file.close
        #then write on socket - here the process HANGS
        #writefds = true
        sleep(1)
        $/ = nil
        readable,writable,error = IO.select(nil, [client], nil, 2) # blocks until the timeout occurs (3 seconds) or until a becomes readable.
        p :r => readable, :w => writable, :e => error
        client.write fileContent
        printf "cmdr$: file uploaded successfully"
        client.close
  }

end

server = TCPServer.open(PORT)  # Socket to listen on port 2000

# Listen for Ctrl-C and disconnect socket gracefully.
Kernel.trap('INT') do
  self.disconnect
  exit
end

loop {                         # Servers run forever


  executioner = server.accept       # Wait for a client to connect
  #executioner.puts('cmdr$: connection accepted. Server time:' + Time.now.ctime.to_s)  # Send the time to the client
  printf "cmdr$: connection established with an execution client, id: %d \n", executioner.__id__
  #puts   "cmdr$: available functions on commander side:"
  #puts   "cmdr$: close: drops the current execution client"
  #puts   "cmdr$: exit: shuts down the server"
  #puts   "cmdr$: we are listening for execution client commands"

  response = executioner.gets()
  if response.byteslice(response.length - 3, 3) == 'EOC'
    puts response.byteslice(0, response.length - 3)
    else
      puts response
  end
  response = nil



  #conversation begins, if command is not close or exit, then sent to client, then waiting for response
  loop {

    servercmd = gets.chomp()
    #servercmd = 'get c:\testfile.exe EOC'
    #servercmd = 'send c:\Tcpview.exe EOC'
  if servercmd == 'close'
    executioner.close()
    printf "cmdr$: execution client id %d dropped \n", executioner.__id__
  elsif servercmd.byteslice(0,4) == 'send'
      executioner.puts(servercmd)
      sendfile(servercmd)

  elsif servercmd.byteslice(0,3) == 'get'

    fileToWrite = servercmd.split("\\", 2)
    ftw = fileToWrite[1].split(" ", 2)
    printf "file to write: %s", ftw[0]
    begin
      file = File.open(ftw[1], 'wb')
      data = executioner.gets()
      file.print data

    #open(ftw[0], 'w') { |f|
     # while chunk = executioner.read()
      #  printf "one chunk written"
       # f.puts chunk

    printf "cmdr$: file %s received", fileToWrite[1]
    rescue IOError => e
      printf "cmdr:$ file write error: %s", e.to_s

    end

    #break
  else
    executioner.puts servercmd + 'EOC'
    printf "cmdr$: command %s sent to execution client \r\n", servercmd
  end

    response = executioner.gets()

    if response.byteslice(response.length - 3, 3) == 'EOC'
      puts response.byteslice(0, response.length - 3)
    else
      puts response
    end
    response = nil
}

}