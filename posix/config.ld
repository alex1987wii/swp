-- -*- lua -*-
file = 'posix.c'
project = 'luaposix'
description = 'POSIX bindings for Lua'

tparam_alias 'string'
tparam_alias 'int'
tparam_alias 'bool'

local upat = "http://www.kernel.org/doc/man-pages/online/pages/man%s/%s.%s.html"
custom_see_handler('^([%w_]+)%((%d)%)$',function(name,section)
    local url = upat:format(section,name,section)
    local name = name .. '(' .. section .. ')'
    return name, url
end)

examples = 'examples'

format = 'discount'
