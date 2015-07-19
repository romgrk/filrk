# file: filrk-model.coffee
# author: romgrk
# description: Model element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Path    = require 'path'
Glob    = require 'glob'

{CompositeDisposable} = require 'atom'
{$, $$, View} = require 'space-pen'

FileOp   = require './operations'
Op       = FileOp.Operation
{System} = new require './system'

module.exports = class FilrkModel

    # Public: {String} path of the cwd
    path: null

    # Public: {Array} of files listed in file-panel
    files: []

    # Public: {Array} of selected paths
    selection: []

    # Public: {System}
    sys: null

    constructor: (path) ->
        @sys = new System('/')
        @changeDir(path || atom.project.getPaths()[0] || process.cwd())

    changeDir: (path) ->
        newPath = @sys.resolve(@path || '', path)
        stats = @sys.f(newPath)
        if stats.exists and stats.isDir
            @path     = stats.path
            @sys.cwd = stats.path
            @processFiles()
            return true
        else
            return false

    processFiles: ->
        entries = @sys.statsList(@path)

        dirs = _.filter entries, (e) -> e.isDir
        rest = _.filter entries, (e) -> not e.isDir

        @files = _.union(dirs, rest)

    getPath: ->
        return @path
