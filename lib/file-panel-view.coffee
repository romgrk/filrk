# file: file-panel-view.coffee
# author: romgrk
# description: View element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Glob    = require 'glob'
Emitter = require('event-kit').Emitter

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

FileOp           = require './operations'
Model            = require './filrk-model'
AutocompletePath = require './autocomplete-path'

Utils = require './utils.coffee'
Path  = Utils.Path

module.exports =
class FilePanelView extends View

    @content: ->
        @div class: 'file-panel select-list', =>
            @div class: 'file-panel-list', =>
                @ul class: 'list-group', outlet: 'listElement'
                    # li items

    # Public: creates a file element (li)
    @createItem: (stats, icon) ->
        $$ ->
            @li class: 'list-item', =>
                @span class: "icon icon-#{icon ? 'plus'}", 'data-name': stats.base, 'data-path': stats.path, stats.base

    ###
    Section: properties
    ###

    model: null
    emitter: null

    dirs: null
    files: null

    subscriptions: null

    ###
    Section: events
    ###

    emit: (args...) -> @emitter.emit args...
    on:   (args...) -> @emitter.on args...
    off:  (args...) -> @emitter.off args...

    ###
    Section: instance
    ###

    constructor: (element) ->
        super()

        @model         = new Model
        @emitter       = new Emitter
        @subscriptions = new CompositeDisposable

        @model.on 'path-changed', @pathChanged.bind(@)
        @model.on 'files-changed', @filesChanged.bind(@)

        if element?
            $(element).replaceWith @element

    registerInputCommands: (commands) ->
        atom.commands.add '.filrk .path-input', commands

    ###
    Section: model observation
    ###

    pathChanged: () ->
        @emit 'path-changed'
        # do nothing

    filesChanged: () ->
        @dirs = @model.dirs
        @files = @model.files

        @renderList()
        @emit 'files-changed'

    ###
    Section: rendering
    ###

    renderList: ->
        @listElement.empty()

        for dir in @model.dirs
            @listElement.append @constructor.createItem(dir, 'file-directory')
        for file in @model.files
            @listElement.append @constructor.createItem(file, 'file-text')

    ###
    Section: access/utils
    ###

    changeDir: (path) ->
        @model.changeDir path

    getPath: ->
        @model.getPath()

    getModel: ->
        @model
