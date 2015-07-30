# file: filrk-model.coffee
# author: romgrk
# description: Model element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Path    = require 'path'
Glob    = require 'glob'
Emitter = require('event-kit').Emitter

{CompositeDisposable} = require 'atom'
{$, $$, View} = require 'space-pen'

FileOp   = require './operations'
Op       = FileOp.Operation
{System} = new require './system'

# TODO refactor. Represents file-panel model
module.exports = class FilrkModel

    emitter: null

    # Public: {String} path of the cwd
    path: null

    # Public: {Array} of files listed in file-panel
    entries: []

    # Public: {Array} of selected paths
    selection: []

    # Public: {System}
    sys: null

    ###
    Section: events
    ###

    emit: (args...) -> @emitter.emit args...
    on:   (args...) -> @emitter.on args...
    off:  (args...) -> @emitter.off args...

    ###
    Section: instance
    ###

    constructor: (path) ->

        @sys     = new System
        @emitter = new Emitter

        @changeDir(path || atom.project.getPaths()[0] || process.cwd())

    changeDir: (path) ->
        newPath = @sys.resolve(@path || '', path)
        stats = @sys.f(newPath)
        if stats.isDir
            @path = stats.path
            @sys.cd stats.path
            @processFiles()
            @emit 'path-changed'
            return true
        else
            return false

    processFiles: ->
        @entries = @sys.statsList(@path)

        @dirs  = _.filter @entries, (e) -> e.isDir
        @files = _.filter @entries, (e) -> not e.isDir

        @entries = _.union(@dirs, @files)

        @emit 'files-changed'

    getPath: ->
        return @path

    getList: ->
        @sys.list @path, base: true

    getStats: ->
        @sys.statsList @path

    getDirs: ->
        @sys.list @path, base: true, dirs: false

    getFiles: ->
        @sys.list @path, base: true, files: false
