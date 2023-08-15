# termoon
Terminal util library - includes serpent, log.lua and lua-term.

[serpent](https://github.com/pkulchenko/serpent)
[log.lua](https://github.com/rxi/log.lua)
[lua-term](https://github.com/hoelzro/lua-term)

termoon doesn't depend on ('require') the libraries mentioned above.
I wanted it to be just one file so that was the only way of doing that.
I also had to slightly modify the libraries.

## Options
set `termoon.colored` to true or false (for now only affects logging) 

## Functions
- termoon.colors.<color>(str)

- termoon.clear()
- termoon.cleareol()

- termoon.cursor.jump(1, 1)
- termoon.cursor.goup(1)
- termoon.cursor.godown(1)
- termoon.cursor.goright(1)
- termoon.cursor.goleft(1)
- termoon.cursor.save()
- termoon.cursor.restore()
- 
- termoon.serialize()
- termoon.deserialize()
- termoon.line()
- termoon.block()
- termoon.dump()
- 
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

- termoon.prinf(str, ...)
- termoon.prinlf(str, vars)
