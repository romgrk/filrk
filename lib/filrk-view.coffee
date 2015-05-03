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


module.exports = class FilrkView extends View
    ############################################################################
    # Section: html content of the view's element
    ############################################################################
    @content: ->
        @div class: 'filrk', =>
            @div class: 'left-panel', =>
                @div class: 'path-bar', outlet: 'pathBar'
                @div class: 'file-panel', =>
                    @ul class: 'list-group', outlet: 'fileList', =>
                        @li class: 'list-item', '~/file.txt'
                        @li class: 'list-item', '~/git/otherfile.txt'
                @div class: 'command-bar', =>
                    @tag 'atom-text-editor', mini:true, outlet: 'input'
            @div class: 'right-panel', =>
                @ul class: 'list-group', =>
                    @li class: 'list-item', '~/file.txt'
                    @li class: 'list-item', '~/git/otherfile.txt'

    ############################################################################
    # Section: instance
    ############################################################################
    model: null

    initialize: () ->
        @editor = @input[0].getModel()

        @model = new Model()
        @model.bind @pathBar.html, 'currentDirectory'

        atom.commands.add '.command-bar > atom-text-editor.mini',
            'core:cancel': => @input.blur()
            'core:confirm': =>
                @model.currentDirectory = @editor.getText()
                @editor.setText ''

    focus: ->
        @input.focus()

    getModel: ->
        @model

    getElement: ->
        @element

    # Tear down any state and detach
    destroy: ->
        @element.remove()
