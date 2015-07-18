

{CompositeDisposable} = require 'atom'
{$, $$} = require 'atom-space-pen-views'

FilrkView = require './filrk-view'

module.exports = Filrk =

    panel:     null
    panelView: null
    filrkView: null
    subscriptions: null

    activate: (state) ->
        @filrkView = new FilrkView(state.filrkViewState)

        @panel     = @createPanel(@filrkView.getElement())
        @panelView = @createPanelView(@panel)

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace',
            'filrk:toggle': => @toggle()

        window.filrk = @

    createPanel: (element) ->
        atom.workspace.addModalPanel(item: element, visible: false)

    createPanelView: (panel) ->
        panelView = $(atom.views.getView(panel))
        panelView.addClass 'filrk-panel'
        panelView.removeClass 'modal overlay'
        panelView.removeClass 'from-top'
        return panelView

    deactivate: ->
        @subscriptions.dispose()
        @filrkView.destroy()
        @panel.destroy()

    toggle: ->
        if @panel.isVisible()
            @panel.hide()
            @restoreFocus()
        else
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
