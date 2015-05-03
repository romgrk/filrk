
_    = require 'underscore-plus'
Fs   = require 'fs-plus'
Path = require 'path'
Glob = require 'glob'

exists  = (path) -> Fs.existsSync path
isDir   = (path) -> Fs.isDirectorySync path
isFile  = (path) -> Fs.isFileSync path
absolute = (path) -> Fs.absolute path
glob    = (path...) -> Glob.sync Path.resolve path...
resolve = (path...) ->
    resolved = Path.resolve path...
    if Fs.exists(resolved)
        Fs.realpathSync Fs.absolute resolved
    else
        resolved
parse   = (path) ->
    _.extend Path.parse(path),
        exists: Fs.exists(path)
        isFile: Fs.isFileSync(path)
        isDir:  Fs.isDirectorySync(path)

# { root: '/',
#   dir: '/home/romgrk/github',
#   base: 'filrk',
#   ext: '',
#   name: 'filrk',
#   isFile: false,
#   isDir: true }

class Operation
    multiple: true
    files:    true
    dirs:     true

    sources:  []
    target: null

    # Public: constructor
    #
    # * `source` array of files/dirs on which the operation will apply
    constructor: (sources) ->
        @setSource sources

    # Public: abstract, the operation implementation
    #
    # Returns nothing.
    execute: (target) ->
        @target = target if target?

    # Public: setter for the files/dirs on which the operation will apply
    #
    # * `source...` list of files/dirs
    #
    # Returns nothing.
    setSource: (sources) ->
        sources = [sources] if typeof sources is 'string'
        unless @multiple
            throw new Error("Multiple entries not allowed") if sources.length isnt 1
        for s in sources
            throw new Error("Following path does not exist: #{s}") unless exists(s)
            isFile = Fs.isFileSync s
            throw new Error("Files not allowed as source") if (not @files and isFile)
            isDir = Fs.isDirectorySync s
            throw new Error("Directories not allowed as source") if (not @dirs and isDir)
            @sources.push resolve(s)

    # Public: set operation target
    #
    # * `target` absolute path to the target
    #
    # Returns nothing.
    setTarget: (path) ->
        @target = path

class Open extends Operation
    execute: ->
        super()

        throw new Error('No entries on which to perform') unless @sources?

        for path in @sources
            atom.workspace.open(path)

class Move extends Operation
    execute: (target) ->
        super(target)
        @target = resolve(@target)

        throw new Error('No entries on which to perform') unless @sources?

        throw new Error("Target does not exist: #{@target}") unless exists(@target)
        # throw new Error("Target is not a directory: #{@target}") unless isDir(@target)

        console.log @target
        targetStat = parse(@target)
        if targetStat.isFile
            throw new Error("Target is a file: #{@target}")

        for source in @sources
            sourceStat = parse(source)
            target = resolve(@target, sourceStat.base)
            @action(source, target)

    action: (source, target) ->
        Fs.moveSync(source, target)

class Copy extends Operation
    action: (source, target) ->
        Fs.copySync(source, target)

class Rename extends Operation
    execute: (target) ->
        super(target)

        throw new Error('No entry on which to perform') unless @sources?

        unless @sources.length == 1
            throw new Error("Multiple sources not allowed")

        if exists(@target)
            throw new Error("Path already exists: #{@target}")

        unless @target.match /^([\/~]|\w:\\\\)/
            sourceStat = parse(@sources[0])
            console.log sourceStat
            @target = resolve(sourceStat.dir, @target)

        Fs.renameSync(@sources[0], @target)

class MakeFile extends Operation
    constructor: (target) ->
        @setTarget target

    execute: (target) ->
        super(target)
        @target = resolve(@target)

        if exists(@target)
            throw new Error("Path already exists: #{@target}")

        Fs.closeSync Fs.openSync(@target, 'wx')

class MakeDir extends Operation
    constructor: (target) ->
        @setTarget target

    execute: (target) ->
        super(target)
        @target = resolve(@target)

        if exists(@target)
            throw new Error("Path already exists: #{@target}")

        Fs.mkdirSync(@target)

module.exports = {Operation, Open, Move, Copy, Rename, MakeFile}

# chlog = resolve(__dirname, '..', 'CHANGELOG.md')
# log = resolve(__dirname, '..', 'LOG.md')
# operation = new MakeFile(log)
# operation.setTarget 'xANGELOG.md'
# operation.execute()
