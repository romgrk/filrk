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

# TODO separate view/model/provider
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

    # List of {Strings}: Candidates for completion
    list: null

    # List of {Strings}: Completion candidates in order
    completions: null

    # {Integer} Index, to cycle to completion list
    completionIndex: 0

    ## Options

    caseSensitiveCompletion: false

    onlyDirectories: false # Filter dirs

    useValueAsPath: false # Use input text as lead

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

    setCandidates: (list) ->
        @list = list

    # Public: cancels the popup and restores input
    cancel: =>
        @input.val @lead
        @hide()

    # Public: hide and reset
    clear: ->
        @hide()
        @listElement.empty()
        @list = null
        @lead = null
        @completions = null

    ###
    Section: completion functions
    ###

    # Private: completes the lead passed as argument
    #
    # Returns nothing.
    completeLead: (lead) =>
        unless @list? and @list.length > 0
            @hide()
            return

        if lead is ''
            @hide()
            return

        @lead = lead

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
            completions = _.filter completions, @isDir, @

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

    isDir: (path) ->
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

        if items.length is 2
            @selectItem 1
            
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

    # Public: get first completion
    getFirstCompletion: () ->
        return @completions[1]

    # Public: get last completion
    getLastCompletion: () ->
        return @completions[@completions.length - 1]
