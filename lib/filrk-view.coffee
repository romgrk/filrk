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

FileOp           = require './operations'
Model            = require './filrk-model'
AutocompletePath = require './autocomplete-path'


module.exports =
class FilrkView extends View

    ###
    Section: html content of the view's element
    ###

    @content: ->
        @div class: 'filrk', =>
            @div class: 'left-panel', =>
                @div class: 'file-panel select-list', =>
                    @ol class: 'list-group', outlet: 'fileList', =>
                        @li class: '', '~/file.txt'
                        @li class: '', '~/git/otherfile.txt'
                @div class: 'command-bar', =>
                    @div class: 'path-container', =>
                        @span class: 'path-label', outlet: 'pathLabel'
                        @input type: 'text', class: 'path-input', outlet: 'pathInput'
            @div class: 'right-panel', =>
                @ul class: 'list-group', =>
                    @li class: 'list-item', '~/file.txt'
                    @li class: 'list-item', '~/git/otherfile.txt'

    # Public: creates a file element (li)
    @entry: (stats, icon) ->
        $$ ->
            @li class: 'list-item', =>
                @span class: "icon icon-#{icon ? 'plus'}", 'data-name': stats.base, 'data-path': stats.path, stats.name

    ###
    Section: instance
    ###

    model: null

    subscriptions: null

    autocomplete: null

    ###
    Section: init/setup
    ###

    constructor: () ->
        super()

        @model         = new Model()
        @subscriptions = new CompositeDisposable
        @autocomplete  = new AutocompletePath(@pathInput)

        @registerInputCommands
            'core:cancel':  => @pathInput.blur()
            'core:confirm': => @inputConfirmed()

        @pathInput.on('input', @inputChanged.bind(@))

        Object.observe(@model, @modelChanged.bind(@))

        @updatePath()
        @updateFileList()

    registerInputCommands: (commands) ->
        atom.commands.add '.command-bar .path-input', commands

    ###
    Section: model observation
    ###

    modelChanged: (changes) ->
        for change in changes
            # console.log change
            name = change.name
            switch name
                when 'cwd' then @updatePath()
                when 'list' then @updateFileList()

    updatePath: ->
        @pathLabel.text         @model.cwd
        @autocomplete.setPath   @model.cwd

    updateFileList: ->
        @fileList.empty()
        for file in @model.list
            icon = if file.isDir then 'file-directory' else 'file-text'
            @fileList.append FilrkView.entry(file, icon)

    ###
    Section: pathInput handling
    ###

    inputConfirmed: ->
        text = @pathInput.val()
        @clearInput()

        @model.setCWD text

    inputChanged: ->
        text = @pathInput.val()

        if text.match /\.\./
            @model.setCWD('..')
            @clearInput()
        else if text.match /~/
            @model.setCWD('~')
            @clearInput()

    clearInput: ->
        @pathInput.val ''

    ###
    Section: display functions
    ###

    focus: ->
        @pathInput.focus()

    getModel: ->
        @model

    getElement: ->
        @element

    # Tear down any state and detach
    destroy: ->
        @element.remove()
