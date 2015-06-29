
_  = require 'underscore-plus'
Fs = require 'fs-plus'


{CompositeDisposable} = require 'atom'
{$, $$, View}         = require 'space-pen'

{System} = require './system'

module.exports =
class AutocompletePath extends View

    input: null

    path: null
    list: null

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

    # Public: input change handler
    inputChanged: =>
        return unless @list? and @list.length > 0

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
        @updateElement(completions)

    updateElement: (items) =>
        @listElement.empty()
        for item in items
            @listElement.append(AutocompletePath.createItem(item))

        unless @isVisible()
            @show()

        # @top @input.top()
        # @left @input.left()
        # console.log @input.top()
        # console.log @input.left()
        console.log @css('top': 0)
        console.log @css('left': 0)


    updateList: (err, files) ->
        if err?
            console.error err
            @list = null
        else
            @list = files

    setPath: (p) ->
        @path = p
        Fs.readdir(@path, @updateList.bind(@))

    attach: ->
        parent = @input.parent()[0]
        parent.appendChild @.get()[0]
