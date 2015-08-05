

{CompositeDisposable} = require 'atom'
{$, $$} = require 'atom-space-pen-views'

FilrkView = require './filrk-view'

module.exports = Filrk =

    panel:     null
    panelElement: null

    filrkView: null

    subscriptions: null

    activate: (state) ->
        @filrkView = new FilrkView(state.filrkViewState)

        @panel     = @createPanel(@filrkView.getElement())

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace',
            'filrk:toggle': => @toggle()
            'filrk:hide': => @hide()
            'filrk:show': => @show()

        window.filrk = @

    createPanel: (element) ->
        panel = atom.workspace.addModalPanel(item: element, visible: false)
        @panelElement = atom.views.getView(panel)
        @panelElement.classList.add 'filrk-panel'
        return panel

    deactivate: ->
        @subscriptions.dispose()
        @filrkView.destroy()
        @panel.destroy()

    toggle: ->
        if @panel.isVisible()
            @hide()
        else
            @show()

    hide: ->
        @panel.hide()
        @restoreFocus()

    show: ->
        @storeFocusedElement()
        @panel.show()
        @filrkView.focus()


    storeFocusedElement: ->
        @previouslyFocusedElement = document.activeElement

    restoreFocus: ->
        if @previouslyFocusedElement?
            @previouslyFocusedElement.focus()
        @previouslyFocusedElement = null

    serialize: ->
        # filrkViewState: @filrkView.serialize()
