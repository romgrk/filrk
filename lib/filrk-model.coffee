# file: filrk-model.coffee
# author: romgrk
# description: Model element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Path    = require 'path'
Glob    = require 'glob'

WatchJS = require 'watchjs'
watch   = WatchJS.watch
unwatch = WatchJS.unwatch

{CompositeDisposable} = require 'atom'
{$, $$, View} = require 'space-pen'

FileOp   = require './operations'
Op       = FileOp.Operation
{System} = new require './system'

module.exports = class FilrkModel

    # Public: {String} path of the cwd
    cwd: null

    # Public: {Array} of files listed in file-panel
    list: []

    # Public: {Array} of selected paths
    selection: []

    # Public: {System}
    sys: null

    constructor: (@cwd) ->

        @cwd ?= System.resolve('.') || System.resolve('~')
        @sys = new System(@cwd)

    setCWD: (path) ->
        path = @sys.resolve(@cwd, path)
        stats = @sys.f(path)
        if stats.exists and stats.isDir
            @cwd     = stats.path
            @sys.cwd = stats.path

            @list = @sys.statsList(@cwd)
        else
            console.warn "Path doesn't exist ", path
