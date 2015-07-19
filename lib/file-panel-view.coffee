# file: file-panel-view.coffee
# author: romgrk
# description: View element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Glob    = require 'glob'

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
    Section: instance
    ###

    model: null

    subscriptions: null

    constructor: (element) ->
        super()

        @model         = new Model
        @subscriptions = new CompositeDisposable

        Object.observe(@model, @modelChanged.bind(@))

        @renderFileList()

        if element?
            $(element).replaceWith @element

    registerInputCommands: (commands) ->
        atom.commands.add '.command-bar .path-input', commands

    ###
    Section: model observation
    ###

    modelChanged: (changes) ->
        for change in changes
            name = change.name
            switch name
                when 'path'  then @pathChanged()
                when 'files' then @filesChanged()

    pathChanged: () ->
        # do nothing

    filesChanged: () ->
        @renderFileList()

    ###
    Section: rendering
    ###

    renderFileList: ->
        @fileList.empty()
        for file in @model.files
            icon = if file.isDir then 'file-directory' else 'file-text'
            @fileList.append @constructor.createItem(file, icon)

    ###
    Section: access/utils
    ###

    getPath: ->
        @model.getPath()

    getModel: ->
        @model
