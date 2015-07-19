
_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Emitter = window.require('event-kit').Emitter # FIXME

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

Path     = require('./utils').Path
{System} = require './system'

module.exports =
class AutocompletePath extends View

    # {EventEmitter}
    emitter: null

    # {JQuery} input to which autocomp is attached
    input: null
    # {JQuery}
    selectedElement: null

    # File system manipulator
    system: null

    # Dir where to look for files
    dir: null

    # Files in *path*
    list: null

    # Completion candidates in order
    completions: null

    # {Integer} Index, to cycle to completion list
    completionIndex: 0

    # Set to true to use input text as the complete path
    useValueAsPath: false

    ###
    Section: elements
    ###

    @content: ->
        @div class: 'autocomplete-path-container', =>
            @div class: 'autocomplete-path-panel', outler: 'panel', =>
                @ul class: 'completion-list', outlet: 'listElement'

    @createItem: (text) ->
        $$ ->
            @li class: 'completion-item', text

    ###
    Section: events
    ###

    # Public: emit event
    emit: (eventName, value) ->
        @emitter.emit eventName, value

    on:  (args...) -> @emitter.on args...
    off: (args...) -> @emitter.off args...

    ###
    Section: instance
    ###

    constructor: (input) ->
        @input = if input[0]? then input else $(input)
        super()

        @system  = new System()
        @emitter = new Emitter()

        @attach()

        @input.css('position': 'relative')
        # @input.on 'input', @completeLead.bind(@)
        @input.on 'blur', => @hide()

        window.autocomp = @

    # Public: set the path in which files are being autocompleted
    #
    # Returns nothing.
    setDir: (path) ->
        @system.cd path
        Fs.readdir(@system.pwd(), @readdirCallback.bind(@))

    # Public: cancels the popup
    cancel: =>
        @hide()

    ###
    Section: completion functions
    ###

    # Private: completes the lead passed as argument
    #
    # Returns nothing.
    completeLead: (lead) =>
        unless @list? and @list.length > 0
            @cancel()
            return

        # lead = @input.val()
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

        completions = _.filter completions, (file) =>
            @system.isDir file
        , @

        completions.unshift lead # lead is kept as candidate 0

        @completionIndex = 0
        @completions     = completions

        if @completions.length == 2
            console.log @getLastCompletion()
            @emit 'single-match-left'

        @populateList(completions)

    # Public: cycle through the completion candidates
    cycle: (moveAmount) =>
        return unless @completions? and @completions.length > 0

        @completionIndex += moveAmount

        if @completionIndex == @completions.length
            @completionIndex = 0
        if @completionIndex < 0
            @completionIndex = @completions.length

        @input.val @completions[@completionIndex]
        @selectItem @completionIndex

    ###
    Section: rendering
    ###

    # Public: highlight *index* children
    selectItem: (index) ->
        if @selectedElement?
            @selectedElement.removeClass 'selected'
        @selectedElement = $ @listElement.children()[index]
        @selectedElement.addClass 'selected'

    # Private: reset and re-position the element, when the popup shows up
    #
    # Returns nothing.
    populateList: (items) =>
        if items.length is 1
            @hide()
            return

        @listElement.empty()
        for item, index in items
            element = AutocompletePath.createItem(item)
            if index is 0
                element.css 'display': 'none'
            @listElement.append(element)

        unless @isVisible()
            @show()

        @css('top': 0)
        @css('left': 0)

    # Public: attach to DOM
    attach: ->
        parent = @input.parent()[0]
        parent.appendChild @.get()[0]

    ###
    Section: model functions
    ###

    # Public: {boolean}
    hasSingleCompletionLeft: ->
        @completions? and @completions.length is 2

    # Public: get next completion
    getLastCompletion: () ->
        return @completions[@completions.length - 1]

    # Private: callback for Fs.readdir
    #
    # Returns nothing.
    readdirCallback: (err, files) ->
        if err?
            console.error err
            @list = null
        else
            @list = files
