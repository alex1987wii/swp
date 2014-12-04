#!/bin/sh

unlock /

if [ -d /usr/share/terminfo ]; then
    echo "/usr/share/terminfo is exist!"
else
    mkdir -p /usr/share
    cp -r ./res/terminfo /usr/share/
fi

if [ -f /usr/bin/lua ]; then
	echo "lua is exist!"
else
	cp lua /usr/bin/
	chmod +x /usr/bin/lua
    ln -s /usr/bin/lua /usr/bin/lua5.1
fi

libs_path=/usr/lib/lua/5.1
lua_module_path=/usr/share/lua/5.1

if [ -d $libs_path ]; then
    echo "$libs_path is exist!"
else
    mkdir -p $libs_path
fi

if [ -d $lua_module_path ]; then
    echo "$lua_module_path is exist!"
else
    mkdir -p $lua_module_path
fi

chmod +x switch_fpl_mode.sh
chmod +x front_panel.lua
chmod +x load2tty0.lua

cp arm-so/*so ${libs_path}/ 
cp *.lua ${lua_module_path}/ 

lock /

./switch_fpl_mode.sh

exit 0

