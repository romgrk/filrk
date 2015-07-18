
_  = require 'underscore-plus'
Fs = require 'fs-plus'


{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

{System} = require './system'

module.exports =
class AutocompletePath extends View

    input: null

    # Dir where to look for files
    path: null

    # Files in *path*
    list: null

    # Completion candidates in order
    completions: null

    # {Integer} Index, to cycle to completion list
    completionIndex: 0

    # Set to true to use input text as the complete path
    useValueAsPath: false

    @content: ->
        @div class: 'autocomplete-path-container', =>
            @div class: 'autocomplete-path-panel', outler: 'panel', =>
                @ul class: 'completion-list', outlet: 'listElement'

    @createItem: (text) ->
        $$ ->
            @li class: 'completion-item', text

    ###
    Section: instance
    ###

    constructor: (input) ->
        @input = if input[0]? then input else $(input)
        super()
        @attach()

        @input.css('position': 'relative')

        @input.on 'input', @inputChanged.bind(@)
        @input.on 'blur', => @hide()

        console.log window.autocomp = @

    # Public: set the path in which files are being autocompleted
    #
    # Returns nothing.
    setPath: (p) ->
        @path = p
        Fs.readdir(@path, @readdirCallback.bind(@))

    # Public: cancels the autocompletion
    cancel: =>
        @hide()

    ###
    Section: event handling
    ###

    # Private: input change handler
    #
    # Returns nothing.
    inputChanged: =>
        unless @list? and @list.length > 0
            @cancel()
            return

        lead = @input.val()
        lists = []
        lists[0] = _.filter @list, (file) ->
            idx = file.indexOf lead
            return true if idx == 0
            return false
        lists[1] = _.filter @list, (file) ->
            idx = file.indexOf lead
            return true if idx == 1
            return false

        completions = _.union(lists...)
        completions.unshift lead        # lead is always candidate 0

        @populateList(completions)

        @completionIndex = 0
        @completions     = completions

    autocompleteNext: ->

    autocompletePrevious: ->

    # Private: reset and re-position the element, when the popup shows up
    #
    # Returns nothing.
    populateList: (items) =>
        @listElement.empty()
        for item in items
            @listElement.append(AutocompletePath.createItem(item))

        unless @isVisible()
            @show()

        @css('top': 0)
        @css('left': 0)

    # Private: callback for Fs.readdir
    #
    # Returns nothing.
    readdirCallback: (err, files) ->
        if err?
            console.error err
            @list = null
        else
            @list = files

    attach: ->
        parent = @input.parent()[0]
        parent.appendChild @.get()[0]
