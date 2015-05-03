# file: filrk-view.coffee
# author: romgrk
# description: View element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Path    = require 'path'
Glob    = require 'glob'

{CompositeDisposable} = require 'atom'
{$, $$, View} = require 'space-pen'

FileOp = require './operations'

module.exports = class FilrkView extends View
    ############################################################################
    # Section: html content of the view's element
    ############################################################################
    @content: ->
        @div class: 'filrk', =>
            @div class: 'left-panel', =>
                @div class: 'path-bar'
                @div class: 'file-panel'
                @div class: 'command-bar', =>
                    @tag 'atom-text-editor', mini:true, outlet: 'input'
            @div class: 'right-panel', =>
                @ol =>
                    @li '~/file.txt'
                    @li '~/git/otherfile.txt'


    initialize: () ->

    # Tear down any state and detach
    destroy: ->
        @element.remove()

    getElement: ->
        @element
