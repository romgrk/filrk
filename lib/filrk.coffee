

{$, $$} = require 'atom-space-pen-views'

FilrkView = require './filrk-view'
{CompositeDisposable} = require 'atom'

module.exports = Filrk =

    filrkView: null
    subscriptions: null

    activate: (state) ->
        @filrkView = new FilrkView(state.filrkViewState)

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace',
            'filrk:toggle': => @toggle()

    deactivate: ->
        @subscriptions.dispose()
        @filrkView.destroy()

    toggle: ->
        if @filrkView.panel.isVisible()
            @filrkView.panel.hide()
        else
            @filrkView.panel.show()

    serialize: ->
        # filrkViewState: @filrkView.serialize()
