# file: filrk-view.coffee
# author: romgrk
# description: View element

_       = require 'underscore-plus'
Fs      = require 'fs-plus'
Path    = require 'path'
Glob    = require 'glob'
{$, $$} = require 'atom-space-pen-views'

{Operation, Open, Move} = require './operations'

# Frequently used functions
exists  = (path) -> Fs.existsSync path
isDir   = (path) -> Fs.isDirectorySync path
isFile  = (path) -> Fs.isFileSync path
glob    = (path...) -> Glob.sync Path.resolve __dirname, path...
resolve = (path...) ->
    resolved = Path.resolve __dirname, path...
    if Fs.exists(resolved)
        Fs.realpathSync Fs.absolute resolved
    else
        resolved
parse   = (path) ->
    _.extend Path.parse(path),
        exists: Fs.exists(path)
        isFile: Fs.isFileSync(path)
        isDir:  Fs.isDirectorySync(path)

module.exports = class FilrkView

    panel: null
    panelView: null

    element: null
    container: null

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @container = $(@element)
        @container.addClass 'flirk'

        @panel = atom.workspace.addModalPanel(item: @element, visible: false)
        @panelView = $(atom.views.getView(@panel))
        @panelView.addClass 'filrk-panel'
        @panelView.removeClass 'modal'
        @panelView.removeClass 'overlay'
        @panelView.removeClass 'from-top'

        @container.append( $$ ->
            @div class: 'text-info', 'hello'
            @div 'yo'
        )

    # Tear down any state and detach
    destroy: ->
        @element.remove()

    getElement: ->
        @element
