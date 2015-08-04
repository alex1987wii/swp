#!/usr/bin/lua

--load2fb.lua 

require "posix"

local bit = require("bit32")

--local fb = "/dev/lcd"
local console = "/dev/tty0"

local die = function (s)
    posix.syslog(posix.LOG_ERR, tostring(s))
end

require "utility"

if "fpl" ~= read_bootmode() then
    die("load2tty0.lua call, is not fpl mode")
    --[[
    os.execute("unlock /")
    os.execute("echo 11111111 > /usr/BIT/fpl_mode_en")
    os.execute("echo global_fpl_mode=BaseBand_MODE > /userdata/Settings/set_fpl_mode.lua")
    os.execute("/usr/bin/switch_fpl_mode.sh")
    --]]
    os.exit(-1)
end

if table.getn(arg) < 1 then
    die("Use: "..arg[0].." program")
    os.exit(-1)
end

local tty, errmsg, errno = posix.open(console, bit.bor(posix.O_RDWR, posix.O_NOCTTY))
if not tty then
    die("err open "..console)
    os.exit(-1)
end

local runproc = arg[1]

local pid = posix.fork()
if pid == nil then
    die("error forking")
elseif pid == 0 then -- child process
    if not posix.dup2 (tty, posix.STDIN_FILENO) then
        die ("error dup2-ing STDIN_FILENO")
    end
    
    if not posix.dup2 (tty, posix.STDOUT_FILENO) then
        die ("error dup2-ing STDOUT_FILENO")
    end
    
    posix.setenv("PATH", "/bin:/sbin:/usr/bin:/usr/sbin", 1)
    posix.setenv("TERM", "xterm", 1)
    posix.setenv("TERMINFO", "/usr/share/terminfo", 1)
    posix.setenv( "LD_LIBRARY_PATH", "/lib", 1)
    
    posix.exec(arg[1])

else -- parent process
    save_stdout = posix.dup(posix.STDOUT_FILENO)
    if not save_stdout then
        die ("error dup-ing save_stdout")
    end

    save_stdin = posix.dup(posix.STDIN_FILENO)
    if not save_stdin then
        die ("error dup-ing save_stdin")
    end

    print("while for pid: "..pid)
    --posix.wait(pid)
    posix.close (tty)
  
end
