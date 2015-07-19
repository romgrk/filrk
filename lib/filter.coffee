
_       = require 'underscore-plus'
Glob    = require 'glob'

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

FileOp           = require './operations'
Model            = require './filrk-model'
AutocompletePath = require './autocomplete-path'

{System} = new require './system.coffee'

Utils  = require './utils.coffee'
Config = Utils.Config
Path   = Utils.Path
Fs     = Utils.Fs

resolve = (paths...) ->
    # paths = _.filter paths, (p) -> p?
    Path.resolve paths...

Filter =
    directories: (files, cwd) ->
        result = _.filter files, (f) ->
            f = resolve(cwd, f) if cwd?
            Fs.isDirectorySync f

        return result

    files: (files, cwd) ->
        result = _.filter files, (f) ->
            f = resolve(cwd, f) if cwd?
            Fs.isDirectorySync f

        return result

    dotFiles: (files, cwd) ->
        result = _.filter files, (f) ->
            Path.basename(f).indexOf('.') is 0


        return result

    match: (files, pattern, cwd) ->
        result = _.filter files, (f) ->
            f = resolve(cwd, f) if cwd?
            f.match(pattern)?

        return result

    basename: (files, pattern, cwd) ->
        result = _.filter files, (f) ->
            f = resolve(cwd, f) if cwd?
            base = Path.basename(f)
            base.match(pattern)?

        return result

    extname: (files, extType, cwd) ->
        result = _.filter files, (f) ->
            ext = Path.extname(f).replace(/^\./, '')
            extType = extType.replace(/^\./, '')
            ext is extType

        return result

    # Public: ordered list; dirs first
    directoriesFirst: (files, cwd) ->
        dirs = _.filter files, (f) ->
            f = resolve(cwd, f) if cwd?
            Fs.isDirectorySync f
        rest = _.filter files, (f) ->
            f = resolve(cwd, f) if cwd?
            not Fs.isDirectorySync f

        return _.union(dirs, rest)
