# file: filrk-view.coffee
# author: romgrk
# description: View element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Glob    = require 'glob'

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

FilePanelModel   = require './filrk-model.coffee'
FilePanelView    = require './file-panel-view.coffee'
FileOp           = require './operations.coffee'
AutocompletePath = require './autocomplete-path.coffee'

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

                @div class: 'file-panel', outlet: 'filePanelDiv'

                @div class: 'command-bar', =>
                    @div class: 'path-container', outlet: 'commandContainer', =>
                        @span class: 'path-label', outlet: 'commandLabel'
                    @div class: 'input-container', outlet: 'inputContainer', =>
                        @input class: 'path-input', outlet: 'input'

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
    filePanel: null

    activePanel: null

    subscriptions: null

    # {AutocompletePath} instance
    autocomplete: null

    ###
    Section: init/setup
    ###

    constructor: () ->
        super()

        @subscriptions = new CompositeDisposable
        @autocomplete  = new AutocompletePath(@input)
        @filePanel     = new FilePanelView(@filePanelDiv)

        @activePanel = @filePanel

        @registerInputCommands
            'core:cancel':  => @autocomplete.cancel()
            'core:confirm': => @inputConfirmed()

            'filrk:make-root': @commandMakeRoot.bind @

            'filrk:clear-input': @clearInput.bind(@)

            'filrk:autocomplete-next': @completeCycle.bind @, 1
            'filrk:autocomplete-previous': @completeCycle.bind @, -1
            'filrk:clear-input': @clearInput.bind(@)

        @input.on('focus', @updatePath.bind(@))
        @input.on('input', @inputChanged.bind(@))
        @input.on('keydown', @inputKeydown.bind(@))

        @autocomplete.on 'single-match-left', =>
            @inputConfirmed() if FilrkView.singleMatchJumps

        @filePanel.on 'path-changed', =>
            @updatePath() if @activePanel is @filePanel

        @updatePath()

    registerPanelCommands: (commands) ->
        atom.commands.add '.filrk .file-panel', commands

    registerInputCommands: (commands) ->
        atom.commands.add '.filrk .path-input', commands

    ###
    Section: model observation
    ###

    findMode:
        render: ->

    pathMode:
        confirm: ->
            value = @input.val()
            newpath = Path.resolve @activePanel.getPath(), value

            if Fs.isDirectorySync(newpath)
                @changeDir value
            else if Fs.existsSync(newpath)
                atom.workspace.open newpath
                @clearInput()
                atom.packages.getActivePackage('filrk').mainModule.hide()
            else
                @clearInput()
                # TODO propose to create dir

        update: ->
            path = @activePanel.getPath()
            @autocomplete.setCandidates @activePanel.getModel().getList()

            pathInfo    = Path.parse path
            displayPath = Path.replaceHomeDirWithTilde(path)
            unless path is pathInfo.root
                displayPath += Path.sep

            @commandLabel.text displayPath

            labelWidth = parseInt(@commandLabel.trueWidth())
            maxWidth   = parseInt(@commandContainer.css('max-width'))
            maxWidth   = 200 if maxWidth is NaN

            if labelWidth < maxWidth
                containerWidth = labelWidth
                labelOffset    = 0
            else
                containerWidth = maxWidth
                labelOffset    = "-#{labelWidth - maxWidth}px"

            @commandContainer.css 'width':   containerWidth
            @commandLabel.css 'margin-left': labelOffset

    # Public: retrieve path from model and render it
    updatePath: ->
        path = @activePanel.getPath()
        @autocomplete.setCandidates @activePanel.getModel().getList()

        pathInfo    = Path.parse path
        displayPath = Path.replaceHomeDirWithTilde(path)
        unless path is pathInfo.root
            displayPath += Path.sep

        @commandLabel.text displayPath

        labelWidth = parseInt(@commandLabel.trueWidth())
        maxWidth   = parseInt(@commandContainer.css('max-width'))
        maxWidth   = 200 if maxWidth is NaN

        if labelWidth < maxWidth
            containerWidth = labelWidth
            labelOffset    = 0
        else
            containerWidth = maxWidth
            labelOffset    = "-#{labelWidth - maxWidth}px"

        @commandContainer.css 'width':   containerWidth
        @commandLabel.css 'margin-left': labelOffset

    ###
    Section: event handling
    ###

    inputConfirmed: ->
        @autocomplete.cancel()

        value = @input.val()
        newpath = Path.resolve @activePanel.getPath(), value

        if Fs.isDirectorySync(newpath)
            @changeDir value
        else if Fs.existsSync(newpath)
            atom.workspace.open newpath
            @clearInput()
            atom.packages.getActivePackage('filrk').mainModule.hide()
        else
            console.log newpath
            @clearInput()
            # TODO propose to create dir


    inputChanged: (event) ->
        text = @input.val()

        if text.match /\.\./
            @changeDir '..'
        else if text.match /~/
            @changeDir '~'
        else if text.match(Path.sep + '$')
            @input.val(text[0...-1])
            @inputConfirmed()
        else
            @autocomplete.completeLead(text)

    inputKeydown: (event) ->
        return if event.repeat
        return unless event.keyCode is 8
        return unless @input.val() is ''

        @changeDir '..'

    completeCycle: (amount) ->
        @autocomplete.cycle amount

        return unless FilrkView.completeSingleMatchJumps
        return unless @autocomplete.hasSingleCompletionLeft()

        completion = @autocomplete.getLastCompletion()
        @input.val completion
        @inputConfirmed()

    ###
    Section: commands
    ###

    commandMakeRoot: ->
        @inputConfirmed()
        # @file

    # Public: set model's working dir to path
    #
    # Returns {boolean} *success*
    changeDir: (path) ->
        success = @activePanel.changeDir path
        if success
            @clearInput()
        return success

    ###
    Section: display functions
    ###

    # Public: clear label and container
    clearLabel: ->
        @commandLabel.text ''
        @commandLabel.css 'margin-left', 0
        @commandContainer.width 0

    # Public: clear input and hide autocomp popup
    clearInput: ->
        @autocomplete.cancel()
        @input.val ''

    show: ->
        super.show()
        @updatePath()

    focus: ->
        @filePanel.renderList()
        @input.focus()

    getFilePanelModel: ->
        @model

    getElement: ->
        @element

    # Tear down any state and detach
    destroy: ->
        @element.remove()
