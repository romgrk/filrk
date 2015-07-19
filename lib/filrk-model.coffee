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
    cwd: null

    # Public: {Array} of files listed in file-panel
    files: []

    # Public: {Array} of selected paths
    selection: []

    # Public: {System}
    sys: null

    constructor: (cwd) ->
        @sys = new System('/')
        @changeDir(cwd || atom.project.getPaths()[0] || process.cwd())

    changeDir: (path) ->
        newPath = @sys.resolve(@cwd || '', path)
        stats = @sys.f(newPath)
        if stats.exists and stats.isDir
            @cwd     = stats.path
            @sys.cwd = stats.path
            @files = @sys.statsList(@cwd)
            return true
        else
            console.log 'couldnt switch to:', path
            console.log 'newPath: ', newPath
            console.log '@cwd: ', @cwd
            console.log stats.exists, stats.isDir
            console.log stats
            return false
