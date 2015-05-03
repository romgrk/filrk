
_     = require 'underscore-plus'
Fs    = require 'fs-plus'
FsEx  = require 'fs-extra'
Path  = require 'path'
Glob  = require 'glob'
Trash = require 'trash'

HIDDEN_FILE = /\/\.[^\/]+$/

class Operation

    ############################################################################
    # Section: Path/FileSystem utilities (static)
    ############################################################################

    @absolute: (path) -> Fs.absolute path
    @relative: (from, to) -> Path.relative(from, to)
    @dirname:  (path) -> Path.dirname path
    @basename: (path) -> Path.basename path

    @exists:   (path) -> Fs.existsSync path
    @isDir:    (path) -> Fs.isDirectorySync path
    @isFile:   (path) -> Fs.isFileSync path
    @isLink:   (path) -> Fs.isSymbolicLinkSync path

    @list:      (path, options={}) ->

        files   = options.files ? true
        dirs    = options.dirs ? true
        visible = options.visible ? true
        hidden  = options.hidden ? true
        base    = options.base ? false

        paths = Fs.listSync path

        unless files
            paths = _.filter(paths, (p) -> not Operation.isFile p)

        unless dirs
            paths = _.filter(paths, (p) -> not Operation.isDir p)

        unless visible
            paths = _.filter(paths, (p) -> p.match(HIDDEN_FILE))

        unless hidden
            paths = _.filter(paths, (p) -> not p.match(HIDDEN_FILE))

        if base
            paths = _.map(paths, Path.basename)

        return paths

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

    @details: (path) ->
        _.extend Path.parse(path),
            exists: Fs.exists(path)
            isFile: Fs.isFileSync(path)
            isDir:  Fs.isDirectorySync(path)
            isLink: Fs.isSymbolicLinkSync(path)

    @unique: (path) ->
        unless Operation.exists(path)
            return path

        details       = Operation.details path
        base          = details.base
        numberedRegex = /(.*)\((\d+)\)(\.[\w\d]+)?$/

        if match = base.match(numberedRegex)
            console.log match
            num = parseInt(match[2]) + 1
            newName = match[1] + "(#{num})"
            newName += match[3] if match[3]?
        else
            newName = details.name + "(1)" + details.ext

        newPath = Operation.resolve(details.dir, newName)
        return Operation.unique newPath


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
    constructor: (sources...) ->
        if sources? and sources.length isnt 0
            if _.isArray(sources[0])
                @setSource sources[0]
            else
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
            unless Operation.exists(s)
                throw new Error("Following path does not exist: #{s}")
            if (not @files) and Operation.isFile(s)
                throw new Error("Files not allowed as source")
            if (not @dirs) and Operation.isDir(s)
                throw new Error("Directories not allowed as source")
            @sources.push Operation.resolve(s)

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
        @target = Operation.resolve(@target)

        throw new Error('No entries on which to perform') unless @sources?

        unless Operation.exists(@target)
            throw new Error("Target does not exist: #{@target}")

        if Operation.isFile(@target)
            throw new Error("Target is a file: #{@target}")

        for source in @sources
            sourceBase = Operation.basename source
            destinationPath = Operation.resolve(@target, sourceBase)
            @action(source, destinationPath)

    action: (source, target) ->
        Fs.moveSync(source, target)

class Copy extends Move
    action: (source, target) ->
        if source == target and not(Operation.isDir(source) and Operation.isDir(target))
            details = Operation.details target
            target = Operation.resolve(
                details.dir,
                "#{details.name}_copy#{details.ext}")
            console.log target
        if Operation.isDir(source)
            Fs.copySync(source, Operation.unique(target))
        else
            rdStream = Fs.createReadStream source
            wrStream = Fs.createWriteStream Operation.unique target
            rdStream.pipe wrStream

class Rename extends Operation
    multiple: false

    execute: (target) ->
        super(target)

        throw new Error('No entry on which to perform') unless @sources?

        unless @sources.length == 1
            throw new Error("Multiple sources not allowed")

        if Operation.exists(@target)
            throw new Error("Path already exists: #{@target}")

        unless Path.isAbsolute @target
            sourceDir = Operation.dirname(@sources[0])
            @target = Operation.resolve(sourceDir, @target)

        Fs.renameSync(@sources[0], @target)

class MakeFile extends Operation
    constructor: (target...) ->
        if target? and target.length isnt 0
            @setTarget Operation.resolve(target...)


    execute: (target...) ->
        if target? and target.length isnt 0
            @setTarget Operation.resolve(target...)

        if Operation.exists(@target)
            throw new Error("Path already exists: #{@target}")

        Fs.closeSync Fs.openSync(@target, 'wx')

class MakeDir extends MakeFile
    execute: (target...) ->
        if target?
            @setTarget Operation.resolve(target...)

        if Operation.exists(@target)
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
            # console.log
            # @sources = _.map @sources, (s) -> s.replace(/(\(|\))/g, '\\$1')
            Trash @sources, (err) ->
                console.error err if err?
        else
            for path in @sources
                FsEx.deleteSync path

module.exports = {
    Operation, Open,
    Move, Copy, Rename,
    MakeFile, MakeDir,
    Delete }
