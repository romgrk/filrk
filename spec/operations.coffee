
Fs = require 'fs-plus'
Operations = require '../lib/operations.coffee'
{Operation, Delete, Move, Copy, Rename, MakeDir, MakeFile} = Operations

# operation = new Delete('/home/romgrk/github/filrk/he')
# operation.setTarget 'xANGELOG.md'
# operation.execute()

filrk = Operation.resolve(__dirname, '..')
log   = Operation.resolve(__dirname, '..', 'CHANGELOG.md')
foo   = Operation.resolve(__dirname, '..', 'foo')
bar   = Operation.resolve(__dirname, '..', 'foo', 'bar.txt')

# console.log new Move
# console.log filrk
# console.log foo
# console.log bar

# console.log Operation.unique '/home/romgrk/github/filrk/foo'

# op = new MakeDir(foo)
# op.execute()
# op = new MakeFile(foo, 'bar.txt')
# op.execute()
# op = new Copy(foo)
# op.setTarget(foo)
# op.execute()
# op = new Move(foo+"/foo(1)")
# op.execute filrk
# op = new Move(bar)
# op.execute filrk
# op = new Rename()
# bars = Operation.glob(foo, 'foo(*')
# console.log bars
# op = new Delete(bars)
# op.execute()
# op = new Rename(filrk+'/foo(1)')
# op.setTarget 'bar2'
# paths = Operation.glob(filrk, 'bar*')
# console.log paths
# op = new Delete(foo)
# op.execute()

# console.log 'List: '
# console.log Operation.list(filrk)
# console.log 'List files: '
# console.log Operation.list(filrk, dirs:false)
# console.log 'List dirs: '
# console.log Operation.list(filrk, files:false)
# console.log 'List hidden: '
# console.log Operation.list(filrk, visible:false)
# console.log 'List visible: '
# console.log Operation.list(filrk, hidden:false)
# console.log 'List base hidden: '
# console.log Operation.list(filrk, {visible:false, base:true})


# console.log Operation.listBasename(pack)
# console.log Operation.listBasename(pack, 'file')
# console.log Operation.listBasename(pack, 'dir')
