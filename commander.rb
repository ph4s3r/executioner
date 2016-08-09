require 'socket'               # Get sockets from stdlib

SIZE = 1024 * 1024 * 10
PORT = 4443

$/ = "EOC"
#	  This above is Input record separator, newline by default. Works like awk’s RS variable. If it is set to nil,
#   A whole file will be read at once. gets, readline, etc. take the input record separator as an optional argument. See also $-0.

printf "cmdr$: TCP server listening on %d port\n", PORT

#This server is actually a controller
#First feature it knows is to shut down the actual connection - when
#Second feature is to run arbitrary command on windows shell and return the values in file

server = TCPServer.open(PORT)  # Socket to listen on port 2000

# Listen for Ctrl-C and disconnect socket gracefully.
Kernel.trap('INT') do
  self.disconnect
  exit
end

loop {                         # Servers run forever


  executioner = server.accept       # Wait for a client to connect
  executioner.puts('cmdr$: connection accepted. Server time:' + Time.now.ctime.to_s)  # Send the time to the client
  printf "cmdr$: connection established with an execution client, id: %d \n", executioner.__id__
  puts   "cmdr$: available functions on commander side:"
  puts   "cmdr$: close: drops the current execution client"
  puts   "cmdr$: exit: shuts down the server"
  puts   "cmdr$:we are listening for execution client commands"

  response = executioner.gets()
  if response.byteslice(response.length - 3, 3) == 'EOC'
    puts response.byteslice(0, response.length - 3)
    else
      puts response
  end
  response = nil



  #conversation begins, if command is not close or exit, then sent to client, then waiting for response
  loop {

    #servercmd = gets.chomp()
    #servercmd = 'get c:\testfile.exe EOC'
    servercmd = 'send c:\Tcpview.exe EOC'
  if servercmd == 'close'
    executioner.close()
    printf "cmdr$: execution client id %d dropped \n", executioner.__id__
  elsif servercmd == 'exit'
    printf "cmdr$: server shutting down"
    break
  elsif servercmd.byteslice(0,4) == 'send'
    printf '1'
    executioner.puts(servercmd)
    printf '2'
    fts = servercmd.split(" ", 3)[1]
    printf '3'
    #sleep(1)
    $/ = nil
    printf '4'
    file = File.open(fts, 'rb')
    printf '5'
    fileContent = file.read
    printf '6'
    $/ = "EOC"
    executioner.puts(fileContent)
    printf '7'

    printf 'file sent: %s' ,fts

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