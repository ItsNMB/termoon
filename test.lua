local termoon = require'termoon'

termoon.clear()
termoon.cleareol()

local cursor = termoon.cursor
cursor.save()
cursor.jump(10, 10)
cursor.goup(2)
cursor.godown(2)
cursor.goright(2)
cursor.goleft(2)
cursor.restore()

local colors = termoon.colors
print(colors.red 'hello')
print(colors.red .. 'hello' .. colors.reset)
print(colors.red .. 'hello' .. colors.reset .. ' world')

termoon.line({a = 1, b = 2, c = 3})
termoon.block({a = 1, b = 2, c = 3})
termoon.dump({a = 1, b = 2, c = 3})
termoon.deserialize(termoon.dump({a = 1, b = 2, c = 3}))

local log = termoon.log
log.trace('trace')
log.debug('debug')
log.info('info')
log.warn('warn')
log.error('error')
log.fatal('fatal')
log.setlevel('trace')

local logf = termoon.logf
logf.trace('%s', 'trace')
logf.debug('%s', 'debug')
logf.info('%s', 'info')
logf.warn('%s', 'warn')
logf.error('%s', 'error')
logf.fatal('%s', 'fatal')

local loglf = termoon.loglf
loglf.trace('{1}', {'trace'})
loglf.debug('{1}', {'debug'})
loglf.info('{1}', {'info'})
loglf.warn('{1}', {'warn'})
loglf.error('{1}', {'error'})
loglf.fatal('{1}', {'fatal'})

termoon.printf('%s', 'hello')
termoon.printlf('{1}', {'hello'})