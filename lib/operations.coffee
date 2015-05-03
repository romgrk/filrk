
_     = require 'underscore-plus'
Fs    = require 'fs-plus'
FsEx  = require 'fs-extra'
Path  = require 'path'
Glob  = require 'glob'
Trash = require 'trash'

class Operation

    ############################################################################
    # Section: Path/FileSystem utilities (static)
    ############################################################################

    @absolute: (path) -> Fs.absolute path
    @relative: (from, to) -> Path.relative(from, to)
    @exists:   (path) -> Fs.existsSync path
    @isDir:    (path) -> Fs.isDirectorySync path
    @isFile:   (path) -> Fs.isFileSync path
    @isLink:   (path) -> Fs.isSymbolicLinkSync path

    @list:      (path, type=null) ->
        paths = Fs.listSync path
        if type isnt null
            return _.filter(paths, (p) -> Fs.isFileSync(p)) if type == 'file'
            return _.filter(paths, (p) -> Fs.isDirectorySync(p)) if type == 'dir'
        else
            return paths

    @listBasename: (path, type=null) -> _.map(@list(path, type), Path.basename)

    @listTree:  (path) -> Fs.listTreeSync path

    @glob:    (path...) -> Glob.sync Path.resolve path...

    @resolve: (path...) ->
        path = for p in path
            Fs.normalize p
        resolved = Path.resolve path...
        if Fs.exists(resolved)
            Fs.realpathSync Fs.absolute resolved
        else
            resolved

    @parse: (path) ->
        _.extend Path.parse(path),
            exists: Fs.exists(path)
            isFile: Fs.isFileSync(path)
            isDir:  Fs.isDirectorySync(path)
            isLink: Fs.isSymbolicLinkSync(path)

    ############################################################################
    # Section: Operators
    ############################################################################

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
        throw new Error('No entries on which to perform') unless @sources?

        for path in @sources
            atom.workspace.open(path)

class Move extends Operation
    execute: (target) ->
        super(target)
        @target = @resolve(@target)

        throw new Error('No entries on which to perform') unless @sources?

        unless @exists(@target)
            throw new Error("Target does not exist: #{@target}")

        if @isFile(@target)
            throw new Error("Target is a file: #{@target}")

        for source in @sources
            sourceStat = @parse(source)
            destinationPath = @resolve(@target, sourceStat.base)
            @action(source, destinationPath)

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

        if @exists(@target)
            throw new Error("Path already exists: #{@target}")

        unless @target.match /^([\/~]|\w:\\\\)/
            sourceStat = @parse(@sources[0])
            @target = @resolve(sourceStat.dir, @target)

        Fs.renameSync(@sources[0], @target)

class MakeFile extends Operation
    constructor: (target) ->
        @setTarget target

    execute: (target) ->
        super(target)
        @target = @resolve(@target)

        if @exists(@target)
            throw new Error("Path already exists: #{@target}")

        Fs.closeSync Fs.openSync(@target, 'wx')

class MakeDir extends Operation
    constructor: (target) ->
        @setTarget target

    execute: (target) ->
        super(target)
        @target = @resolve(@target)

        if @exists(@target)
            throw new Error("Path already exists: #{@target}")

        Fs.mkdirSync(@target)

class Delete extends Operation
    realDelete: false

    constructor: (sources, real=false) ->
        super(sources)
        @realDelete = real

    execute: (real=false) ->
        @realDelete = real

        throw new Error('No entries on which to perform') unless @sources?

        unless @realDelete
            Trash @sources
        else
            for path in @sources
                FsEx.deleteSync path

module.exports = {
    Operation, Open,
    Move, Copy, Rename,
    MakeFile, MakeDir,
    Delete }
