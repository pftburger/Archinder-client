class TemplateScrollComponent extends ScrollComponent
    @define "numberOfItems",
        get: -> @options.numberOfItems
        set: ( int ) -> 
            unless int == @options.numberOfItems
                @options.numberOfItems = int
                @emit "change:numberOfItems"
    
    @define "templateItem",
        get: -> @options.templateItem
        set: ( layer ) -> @options.templateItem = layer
    
    @define "gutter",
        get: -> @options.gutter
        set: ( int ) ->
            unless int == @options.gutter
                @options.gutter = int
                @emit "change:gutter"
        
    @define "forItemAtIndex",
        get: -> @options._forItemAtIndex
        set: ( fn ) ->
            unless fn == @options._forItemAtIndex
                @options._forItemAtIndex = fn
                @emit "change:forItemAtIndex"
    
    constructor: ( @options={} ) ->
        @options.numberOfItems ?= 1
        @options.gutter ?= 10
        @options._forItemAtIndex ?= null
        @options.templateItem ?= null
        
        super @options
        
        # Update events
        @on "change:numberOfItems", -> 
            updateComponent @, @options._forItemAtIndex
        @on "change:forItemAtIndex", -> 
            updateComponent @, @options._forItemAtIndex
        @on "change:gutter", -> 
            updateComponent @, @options._forItemAtIndex
            
    destroyChildren = ( layer ) ->
        layer.children?.forEach ( layer ) ->
            layer.destroy()

    updateComponent = ( component, cb ) ->
        if cb && component.numberOfItems
            destroyChildren component.content
            
            itemsLen = component.numberOfItems - 1
            padding = component.gutter
            proto = component.templateItem

            for index in [ 0..itemsLen ]
                layer = cb( index, proto )
                layer.props =
                    parent: component.content,
                    y: index * ( layer.height + padding ),
                    name: layer.name + " " + index

            # Force update of component
            component.updateContent()
    
    # Look into layer.descendants as an alternative
    flattenChildren = ( layer ) ->
        return [ layer ].concat( layer.children.reduce( ( arr, layer ) ->
            return arr.concat flattenChildren layer
        ,[] ) )
    
    layersWithTemplateTags = ( layer ) ->
        return flattenChildren( layer )
        .filter ( layer ) ->
            return /{([^}]*)}/.test layer.text
    
    @applyTemplate = ( layer, options={}, formatterOptions={} ) ->
        layersWithTemplateTags( layer ).forEach ( layer ) ->
            layer.templateFormatter ?= formatterOptions
            layer.template ?= options

module.exports = TemplateScrollComponent