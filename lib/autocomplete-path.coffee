#
# file: autocomplete-path.coffee
# author: romgrk
# description:
#   autocomplete extension for any input[text]
#   this class is both view and provider

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Emitter = require('event-kit').Emitter

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

    # List of {Strings}: Completion candidates in order
    completions: null

    # {Integer} Index, to cycle to completion list
    completionIndex: 0

    # Filter dirs
    onlyDirectories: false

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
        @input.on 'blur', => @hide()

        window.autocomp = @

    # Public: set the path in which files are being autocompleted
    #
    # Returns nothing.
    setDir: (path) ->
        @system.cwd = path
        @list = @system.list(path, base: true)

    setCandidates: (list) ->
        @list = list

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

        lowerCaseLead = lead.toLowerCase()

        lists = []
        lists[0] = _.filter @list, (file) ->
            idx = file.toLowerCase().indexOf lowerCaseLead
            return true if idx == 0
            return false
        lists[1] = _.filter @list, (file) ->
            idx = file.toLowerCase().indexOf lowerCaseLead
            return true if idx == 1
            return false

        completions = _.union(lists...)

        # Keep only directories
        if @onlyDirectories
            completions = _.filter completions, @filterDir, @

        # *lead* is kept as candidate 0
        completions.unshift lead

        @completionIndex = 0
        @completions     = completions

        if @completions.length == 2
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
    Section: filters
    ###

    filterDir: (path) ->
        console.log path, @system.isDir(path)
        return @system.isDir(path)

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
