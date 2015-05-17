# file: filrk-view.coffee
# author: romgrk
# description: View element

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
Model  = require './filrk-model'


module.exports =
class FilrkView extends View

    ###
    Section: html content of the view's element
    ###

    @content: ->
        @div class: 'filrk', =>
            @div class: 'left-panel', =>
                @div class: 'path-bar', outlet: 'pathBar'
                @div class: 'file-panel select-list', =>
                    @ol class: 'list-group', outlet: 'fileList', =>
                        @li class: '', '~/file.txt'
                        @li class: '', '~/git/otherfile.txt'
                @div class: 'command-bar', =>
                    @tag 'atom-text-editor', mini:true, outlet: 'input'
            @div class: 'right-panel', =>
                @ul class: 'list-group', =>
                    @li class: 'list-item', '~/file.txt'
                    @li class: 'list-item', '~/git/otherfile.txt'

    # Public: creates a file element (li)
    @file: (path) ->
        $$ ->
            @li class: 'list-item', path

    ###
    Section: instance
    ###

    model: null
    subscriptions: null

    ###
    Section: init/setup
    ###

    constructor: () ->
        super()

        @model = new Model()
        @subscriptions = new CompositeDisposable

        @editor = @input[0].getModel()

        @registerInputCommands
            'core:cancel': => @input.blur()
            'core:confirm': =>
                @model.currentDirectory = @editor.getText()

        @model.link @pathBar.html.bind(@pathBar), 'currentDirectory'
        @model.link @setFileList, 'list'

        @input.onDidChange(@textChanged.bind(@))

    registerInputCommands: (commands) ->
        atom.commands.add '.command-bar > atom-text-editor.mini', commands

    setFileList: (list) =>
        @fileList.empty()
        for path in list
            @fileList.append FilrkView.file(path)

    ###
    Section: Input handling
    ###

    textChanged: ->



    ###
    Section: display functions
    ###

    focus: ->
        @input.focus()

    getModel: ->
        @model

    getElement: ->
        @element

    # Tear down any state and detach
    destroy: ->
        @element.remove()
