# termoon
Terminal util library - includes serpent, log.lua and lua-term.

[serpent](https://github.com/pkulchenko/serpent)
[log.lua](https://github.com/rxi/log.lua)
[lua-term](https://github.com/hoelzro/lua-term)

termoon doesn't depend on ('require') the libraries mentioned above.
I wanted it to be just one file so that was the only way of doing that.
I also had to slightly modify the libraries.
Should work with Lua Versions 5.3, 5.2 and 5.1 but i only tested 5.4.

## Options
set `termoon.colored` to true or false (for now only affects logging) 

## Functions
### Colors
- termoon.colors.<color>(str)
### Clearing
- termoon.clear()
- termoon.cleareol()
### Cursor
- termoon.cursor.jump(1, 1)
- termoon.cursor.goup(1)
- termoon.cursor.godown(1)
- termoon.cursor.goright(1)
- termoon.cursor.goleft(1)
- termoon.cursor.save()
- termoon.cursor.restore()
### Serialization
- termoon.serialize()
- termoon.deserialize()
- termoon.line()
- termoon.block()
- termoon.dump()
### Logging
- termoon.log.setlevel(lvl)
- termoon.log.setfile(file)
- termoon.log.trace(...)
- termoon.log.debug(...)
- termoon.log.info(...)
- termoon.log.warn(...)
- termoon.log.error(...)
- termoon.log.fatal(...)
- termoon.logf.<type>(str, ...)
- termoon.loglf.<type>(str, vars)
### Formatted printing
- termoon.prinf(str, ...)
- termoon.prinlf(str, vars)
