
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


class Filter

    # {System} instance
    system: null

    constructor: (@system) ->
       return

    # Filters

    dirs: (paths) ->
        return Fs.isDirectorySync path

    files: (path) ->
        return Fs.isFileSync path
