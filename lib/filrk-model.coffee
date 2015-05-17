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

FileOp = require './operations'
Op     = FileOp.Operation

module.exports = class FilrkModel

    # Public: {String} path of the cwd
    currentDirectory: null

    # Public: {Array} of files listed in file-panel
    list: null

    # Public: {Array} of selected paths
    selection: null

    constructor: (@currentDirectory=Op.resolve('~')) ->
        @list      = []
        @selection = []

        @link =>
            @list = Op.list(@currentDirectory, {base:true})
            console.log @list
        , 'currentDirectory'

    link: (callback, property) ->
        watch @, property, =>
            callback @[property]
