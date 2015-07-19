# file: filrk-view.coffee
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
class FilrkView extends View

    # Options
    @singleMatchJumps         = false
    @completeSingleMatchJumps = true

    ###
    Section: html content of the view's element
    ###

    @content: ->
        @div class: 'filrk', =>
            @div class: 'left-panel', =>

                @div class: 'file-panel select-list', outlet: 'filePanel', =>
                    @div class: 'file-panel-list', =>
                        @ul class: 'list-group', outlet: 'fileList', =>
                            @li class: '', '~/file.txt'
                            @li class: '', '~/git/otherfile.txt'

                @div class: 'command-bar', =>
                    @div class: 'path-container', outlet: 'pathContainer', =>
                        @span class: 'path-label', outlet: 'pathLabel'
                    @div class: 'input-container', outlet: 'inputContainer', =>
                        @input class: 'path-input', outlet: 'pathInput'

            @div class: 'right-panel', =>
                @ul class: 'list-group', =>
                    @li class: 'list-item', '~/file.txt'
                    @li class: 'list-item', '~/git/otherfile.txt'

    # Public: creates a file element (li)
    @entry: (stats, icon) ->
        $$ ->
            @li class: 'list-item', =>
                @span class: "icon icon-#{icon ? 'plus'}", 'data-name': stats.base, 'data-path': stats.path, stats.base

    ###
    Section: instance
    ###

    model: null

    subscriptions: null

    # {AutocompletePath} instance
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
            'core:cancel':  => @autocomplete.cancel()
            'core:confirm': => @inputConfirmed()

            'filrk:make-root': @commandMakeRoot.bind @

            'filrk:clear-input': @clearInput.bind(@)

            'filrk:autocomplete-next': @completeCycle.bind @, 1
            'filrk:autocomplete-previous': @completeCycle.bind @, -1
            'filrk:clear-input': @clearInput.bind(@)

        @pathInput.on('focus', @updatePath.bind(@))
        @pathInput.on('input', @inputChanged.bind(@))

        @autocomplete.on 'single-match-left', =>
            @inputConfirmed() if FilrkView.singleMatchJumps

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
            name = change.name
            switch name
                when 'cwd'   then @updatePath()
                when 'files' then @updateFileList()

    # Public: retrieve path from model and render it
    updatePath: ->
        path = @model.cwd
        pathInfo = Path.parse path

        displayPath = Path.replaceHomeDirWithTilde(path)
        unless path is pathInfo.root
            displayPath += Path.sep

        @autocomplete.setDir path
        @pathLabel.text displayPath

        labelWidth = parseInt(@pathLabel.trueWidth())
        maxWidth   = parseInt(@pathContainer.css('max-width'))
        maxWidth   = 200 if maxWidth is NaN

        if labelWidth < maxWidth
            containerWidth = labelWidth
            labelOffset    = 0
        else
            containerWidth = maxWidth
            labelOffset    = "-#{labelWidth - maxWidth}px"

        @pathContainer.css 'width':   containerWidth
        @pathLabel.css 'margin-left': labelOffset

    updateFileList: ->
        @fileList.empty()
        for file in @model.files
            icon = if file.isDir then 'file-directory' else 'file-text'
            @fileList.append FilrkView.entry(file, icon)

    ###
    Section: event handling
    ###

    inputConfirmed: ->
        @autocomplete.cancel()

        value = @pathInput.val()
        success = @changeDir value

        # unless success
        #     if @autocomplete.hasSingleCompletionLeft()
        #         @changeDir @autocomplete.getLastCompletion()

        # TODO
        # parse input to detect if path really exists
        # if not, ask to create a dir/file with that name

    inputChanged: (event) ->
        text = @pathInput.val()

        if text.match /\.\./
            @changeDir '..'
        else if text.match /~/
            @changeDir '~'
        else if text.match(Path.sep + '$')
            @inputConfirmed()
        else
            @autocomplete.completeLead(text)

    completeCycle: (amount) ->
        @autocomplete.cycle amount

        return unless FilrkView.completeSingleMatchJumps
        return unless @autocomplete.hasSingleCompletionLeft()

        completion = @autocomplete.getLastCompletion()
        @pathInput.val completion
        console.log 'completed and confirmed: ', completion
        @inputConfirmed()

    ###
    Section: commands
    ###

    commandMakeRoot: ->
        @inputConfirmed()
        # @file


    ###
    Section: display functions
    ###

    # Public: set model's working dir to path
    #
    # Returns {boolean} *success*
    changeDir: (path) ->
        success = @model.changeDir path
        console.log success, path
        @clearInput() if success
        return success

    # Public: clear input and hide autocomp popup
    clearInput: ->
        @autocomplete.cancel()
        @pathInput.val ''

    show: ->
        super.show()
        @updatePath()

    focus: ->
        @pathInput.focus()

    getModel: ->
        @model

    getElement: ->
        @element

    # Tear down any state and detach
    destroy: ->
        @element.remove()
