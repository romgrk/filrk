
_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Emitter = require('event-kit').Emitter

{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

{System} = require './system'

module.exports =
class AutocompletePath extends View

    # {EventEmitter}
    emitter: null

    # {JQuery} input to which autocomp is attached
    input: null
    # {JQuery}
    selectedElement: null

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

        @emitter = new Emitter()

        @attach()

        @input.css('position': 'relative')
        # @input.on 'input', @completeLead.bind(@)
        @input.on 'blur', => @hide()

        window.autocomp = @

    # Public: set the path in which files are being autocompleted
    #
    # Returns nothing.
    setDir: (p) ->
        @dir = p
        Fs.readdir(@dir, @readdirCallback.bind(@))

    # Public: cancels the popup
    cancel: =>
        @hide()

    # Public: emit event
    emit: (eventName, value) ->
        @emitter.emit eventName, value

    on:  (args...) -> @emitter.on args...
    off: (args...) -> @emitter.off args...

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

        completions.unshift lead # lead is kept as candidate 0
        @completionIndex = 0
        @completions     = completions

        @populateList(completions)

    # Public: cycle through the completion candidates
    cycle: (moveAmount) =>
        return unless @completions? and @completions.length > 0

        if @completions.length == 2
            console.log @completions
            @emit 'single-match-left'

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

    attach: ->
        parent = @input.parent()[0]
        parent.appendChild @.get()[0]

    # Private: callback for Fs.readdir
    #
    # Returns nothing.
    readdirCallback: (err, files) ->
        if err?
            console.error err
            @list = null
        else
            @list = files
