class KDSplitView extends KDView

  constructor:(options = {},data)->

    options.type      or= "vertical"    # "vertical" or "horizontal"
    options.resizable  ?= yes           # yes or no
    options.sizes     or= ["50%","50%"] # an Array of Strings such as ["50%","50%"] or ["500px","150px",null] and null for the available rest area
    options.minimums  or= null          # an Array of Strings
    options.maximums  or= null          # an Array of Strings
    options.views     or= null          # an Array of KDViews
    options.fixed     or= []            # an Array of Booleans
    options.duration  or= 200           # a Number in miliseconds
    options.separator or= null          # a KDView instance or null for default separator
    options.colored    ?= no
    options.animated   ?= yes           # a Boolean

    super options,data

    @panels       = []
    @panelsBounds = []
    @resizers     = []
    @sizes        = []

  viewAppended:->

    @sizes = @_sanitizeSizes()

    @_putClassNames()
    @_createPanels()
    @_calculatePanelBounds()
    @_putPanels()
    @_setPanelPositions()
    @_putViews()

    if @options.resizable and @panels.length
      @_createResizers()

    @listenWindowResize()

  _putClassNames:->
    @setClass "kdsplitview kdsplitview-#{@options.type} #{@options.cssClass}"

  # CREATE PANELS
  _createPanels:->
    panelCount = @options.sizes.length
    @panels = for i in [0...panelCount]
      @_createPanel i

  _createPanel:(index)->

    {type, fixed, minimums, maximums} = @getOptions()
    panel = new KDSplitViewPanel
      cssClass : "kdsplitview-panel panel-#{index}"
      index    : index
      type     : type
      size     : @_sanitizeSize @sizes[index]
      fixed    : yes                            if fixed[index]
      minimum  : @_sanitizeSize minimums[index] if minimums
      maximum  : @_sanitizeSize maximums[index] if maximums

    panel.on "KDObjectWillBeDestroyed", => @_panelIsBeingDestroyed panel

    return panel

  _calculatePanelBounds:()->
    @panelsBounds = for size,i in @sizes
      if i is 0
        0
      else
        offset = 0
        for prevSize in [0...i]
          offset += @sizes[prevSize]
        offset

  _putPanels:()->
    for panel in @panels
      @addSubView panel
      if @options.colored
        panel.$().css backgroundColor : __utils.getRandomRGB()

  _setPanelPositions:->
    for panel,i in @panels
      panel._setSize @sizes[i]
      panel._setOffset @panelsBounds[i]

  # CREATE RESIZERS
  _createResizers:->
    @resizers = for i in [1...@sizes.length]
      @_createResizer i
    @_putResizers()
    @_setResizerPositions()

  _createResizer:(index)->
    resizer = new KDSplitResizer
      cssClass : "kdsplitview-resizer #{@options.type}"
      type     : @options.type
      panel0   : @panels[index-1]
      panel1   : @panels[index]

  _putResizers:->
    @addSubView resizer for resizer in @resizers

  _setResizerPositions:->
    resizer._setOffset @panelsBounds[i+1] for resizer,i in @resizers


  # PUT VIEWS
  _putViews:->
    @options.views ?= []
    for view,i in @options.views
      if view instanceof KDView
        @setView view,i

  # HELPERS
  _sanitizeSizes:()->
    @_setMinsAndMaxs()
    o             = @getOptions()
    nullCount     = 0
    totalOccupied = 0
    splitSize     = @_getSize()

    newSizes = for size,i in (if @sizes.length > 0 then @sizes else o.sizes)
      if size is null
        # log size, "null"
        nullCount++
        null
      else
        panelSize = @_sanitizeSize size
        @_getLegitPanelSize size,i
        # check maxs and mins
        totalOccupied += panelSize
        panelSize

    @sizes = for size in newSizes
      if size is null
        nullSize = (splitSize - totalOccupied) / nullCount
        Math.round(nullSize)
      else
        Math.round(size)

  _sanitizeSize:(size)->
    if "number" is typeof size or /px$/.test(size)
      parseInt size,10
    else if /%$/.test size
      splitSize = @_getSize()
      splitSize / 100 * parseInt size,10

  _setMinsAndMaxs:->
    @options.minimums ?= []
    @options.maximums ?= []
    panelAmount = @options.sizes.length or 2
    for i in [0...panelAmount]
      @options.minimums[i] = if @options.minimums[i] then @_sanitizeSize @options.minimums[i] else -1
      @options.maximums[i] = if @options.maximums[i] then @_sanitizeSize @options.maximums[i] else 99999

  _getSize:()->
    if @options.type.toLowerCase() is "vertical" then @getWidth() else @getHeight()

  _setSize:(size)->
    if @options.type.toLowerCase() is "vertical" then @setWidth size else @setHeight size


  _getParentSize:->
    type = @options.type.toLowerCase()
    if @parent
      if type is "vertical" then @parent.getWidth() else @parent.getHeight()
    else
      if type is "vertical" then $(window).width() else $(window).height()

  _getLegitPanelSize:(size,index)->
    size =
      if @options.minimums[index] > size
        @options.minimums[index]
      else if @options.maximums[index] < size
        @options.maximums[index]
      else
        size

  _resetSizeValues:->

    # THIS RESIZES ALL PANELS BY THEIR CURRENT PERCENTAGES <- BAD

    # for i in [0...@sizes.length]
    #   splitSize = @_getSize()
    #   panelSize = @panels[i].size = @panels[i]._getSize()

    #   newSizeInPercentage = Math.round panelSize * 100 / splitSize

    #   if newSizeInPercentage isnt Infinity and isNaN(newSizeInPercentage) isnt true
    #     @options.sizes[i] = "#{newSizeInPercentage}%"
    #   else
    #     @options.sizes[i] = null

    # total = 0
    # total += parseInt(size,10) for size in @options.sizes
    # lastPanelSize = parseInt(@options.sizes[@options.sizes.length-1])
    # if total < 100
    #   lastPanelSize += 100 - total
    #   @options.sizes[@options.sizes.length-1] = "#{lastPanelSize}%"
    # else
    #   lastPanelSize -= total - 100
    #   @options.sizes[@options.sizes.length-1] = "#{lastPanelSize}%"


    # for size,index in @getOptions().sizes
    #   newSizeInPercentage = Math.round @panels[index]._getSize() * 100 / @_getSize()
    #   @getOptions().sizes[index] = if newSizeInPercentage isnt Infinity and isNaN(newSizeInPercentage) isnt true
    #     "#{newSizeInPercentage}%"
    #   else null


  # EVENT HANDLING
  _windowDidResize:(event)=>

    # this is a hack and should be removed
    # because we have an animation in contentpanel
    # i had to do this otherwise a big refactoring is necessary
    # sinan 6/2012
    @utils.wait 300, =>
      @_setSize @_getParentSize()
      @_resetSizeValues()

      @_sanitizeSizes()
      @_calculatePanelBounds()
      @_setPanelPositions()

      # find a way to do that for when parent get resized and split reachs a min-width
      # if @getWidth() > @_getParentSize() then @setClass "min-width-reached" else @unsetClass "min-width-reached"
      if @options.resizable
        @_setResizerPositions()

  mouseUp:(event)->
    @$().unbind "mousemove.resizeHandle"
    @_resizeDidStop event

  _panelReachedMinimum:(panelIndex)->
    @panels[panelIndex].emit "PanelReachedMinimum"
    @emit "PanelReachedMinimum", panel : @panels[panelIndex]

  _panelReachedMaximum:(panelIndex)->
    @panels[panelIndex].emit "PanelReachedMaximum"
    @emit "PanelReachedMaximum", panel : @panels[panelIndex]

  _resizeDidStart:(event)=>
    $('body').addClass "resize-in-action"
    @emit "ResizeDidStart", orgEvent : event

  _resizeDidStop:(event)=>
    @emit "ResizeDidStop", orgEvent : event
    @utils.wait 300, ->
      $('body').removeClass "resize-in-action"

  ### PUBLIC METHODS ###
  resizePanel:(value = 0,panelIndex = 0,callback = noop)=>
    @_resizeDidStart()

    value     = @_sanitizeSize value
    panel0    = @panels[panelIndex]
    isReverse = no

    if panel0.size is value
      @_resizeDidStop()
      callback()
      return

    # get the secondary panel and resizer which will be resized/positioned accordingly
    panel1 = unless @panels.length - 1 is panelIndex
      p1index = panelIndex + 1
      resizer = @resizers[panelIndex] if @options.resizable
      @panels[p1index]
    else
      isReverse = yes
      p1index   = panelIndex-1
      resizer   = @resizers[p1index] if @options.resizable
      @panels[p1index]

    # stop if it's not doable

    # totalActionArea = panel0._getSize() + panel1._getSize() # trying to improve performance here
    totalActionArea = panel0.size + panel1.size

    return no if value > totalActionArea

    p0size    = @_getLegitPanelSize(value,panelIndex)
    surplus   = panel0.size - p0size
    p1newSize = panel1.size + surplus
    p1size    = @_getLegitPanelSize(p1newSize,p1index)

    raceCounter = 0
    race = ()=>
      raceCounter++
      if raceCounter is 2
        @_resizeDidStop()
        callback()

    unless isReverse
      p1offset = (panel1._getOffset() - surplus)
      if @options.animated
        panel0._animateTo p0size,race
        panel1._animateTo p1size,p1offset,race
        resizer._animateTo p1offset if resizer
      else
        panel0._setSize p0size
        race()
        panel1._setSize p1size,
        panel1._setOffset p1offset
        race()
        resizer._setOffset p1offset if resizer

    else
      p0offset = (panel0._getOffset() + surplus)
      if @options.animated
        panel0._animateTo p0size,p0offset,race
        panel1._animateTo p1size,race
        resizer._animateTo p0offset if resizer
      else
        panel0._setSize p0size
        panel0._setOffset p0offset
        race()
        panel1._setSize p1size
        race()
        resizer._setOffset p0offset if resizer


  hidePanel:(panelIndex,callback = noop)=>
    panel = @panels[panelIndex]
    panel._lastSize = panel._getSize()
    @resizePanel 0,panelIndex,()=>
      callback.call @,(panel : panel, index : panelIndex )


  showPanel:(panelIndex,callback = noop)=>
    panel = @panels[panelIndex]
    newSize = panel._lastSize or @options.sizes[panelIndex] or 200
    panel._lastSize = null
    @resizePanel newSize,panelIndex,()->
      callback.call @,(panel : panel, index : panelIndex )

  getPanelIndex:(panel)->

    for p,i in @panels
      if p.getId() is panel.getId()
        return i

  splitPanel:(index, options)->

    newPanelOptions = $.extend
      minimum : null
      maximum : null
      view    : null
    ,options

    o = @options
    isLastPanel = if @resizers[index] then no else yes

    # DO PANEL

    # CREATE NEW PANEL
    panelToBeSplitted = @panels[index]
    @panels.splice index + 1, 0, newPanel = @_createPanel(index)
    @sizes.splice index + 1, 0, @sizes[index]/2
    @sizes[index] = @sizes[index]/2

    # MINS AND MAXS ARE NOT FUNCTIONAL YET ON NEWLY CREATED PANELS
    # BUT TO AVOID CONFLICTS WE UPDATE THEM HERE
    o.minimums.splice index + 1, 0, newPanelOptions.minimum
    o.maximums.splice index + 1, 0, newPanelOptions.maximum
    o.views.splice index + 1, 0, newPanelOptions.view
    o.sizes = @sizes

    # MIMIC @addSubView(newPanel)
    @subViews.push newPanel
    newPanel.setParent @
    panelToBeSplitted.$().after newPanel.$()
    newPanel.propagateEvent KDEventType: 'viewAppended'

    # POSITION NEW PANEL
    newSize = panelToBeSplitted._getSize() / 2
    panelToBeSplitted._setSize newSize
    newPanel._setSize newSize
    newPanel._setOffset panelToBeSplitted._getOffset() + newSize
    @_calculatePanelBounds()

    # COLORIZE PANELS
    # panelToBeSplitted.$().css backgroundColor : __utils.getRandomRGB()
    # newPanel.$().css backgroundColor : __utils.getRandomRGB()

    # RE-ENUMERATE PANELS
    for panel,i in @panels[index+1...@panels.length]
      panel.index = newIndex = index+1+i
      panel.unsetClass("panel-#{index+i}").setClass("panel-#{newIndex}")

    # DO RESIZER

    unless isLastPanel
      # POSITION OLD RESIZER
      oldResizer = @resizers[index]
      oldResizer._setOffset @panelsBounds[index+1]
      oldResizer.panel0 = panelToBeSplitted
      oldResizer.panel1 = newPanel
      # CREATE NEW RESIZER
      @resizers.splice index+1, 0, newResizer = @_createResizer index+2
      # POSITION NEW RESIZER
      newResizer._setOffset @panelsBounds[index+2]
      # APPEND NEW RESIZER
      oldResizer.$().after newResizer.$()
      # MIMIC @addSubView(newResizer)
      @subViews.push newResizer
      newResizer.propagateEvent KDEventType: 'viewAppended'
    else
      # CREATE NEW RESIZER
      @resizers.push newResizer = @_createResizer index+1
      # POSITION NEW RESIZER
      newResizer._setOffset @panelsBounds[index+1]
      # APPEND NEW RESIZER
      @addSubView newResizer

    return newPanel

  _panelIsBeingDestroyed:(panel)->

    index = @getPanelIndex panel
    log "><><#{index}><><"
    o = @getOptions()
    # log @panels.splice       index, 1
    # log @sizes.splice        index, 1
    # log @panelsBounds.splice index, 1
    @panels       = @panels.slice(0,index).concat(@panels.slice(index+1))
    @sizes        = @sizes.slice(0,index).concat(@sizes.slice(index+1))
    @panelsBounds = @panelsBounds.slice(0,index).concat(@panelsBounds.slice(index+1))
    o.minimums.splice    index, 1
    o.maximums.splice    index, 1
    o.views.splice       index, 1 if o.views[index]?


    log "panelsBounds", @panelsBounds
    log "sizes", @sizes

    # if o.resizable and @panels.length > 1
    #   for r,i in @resizers
    #     log "destroying resizer", i
    #     r.destroy()
    #   @resizers = []
    #   @utils.wait 310, =>
    #     @_createResizers()


  removePanel:(index)->

    l = @panels.length
    if l is 1
      warn "this is the only panel left"
      return no

    panel = @panels[index]
    panel.destroy()

    if index is 0
      # log "FIRST ONE"
      r = @resizers.shift()
      r.destroy()
      if res = @resizers[0]
        res.panel0 = @panels[0]
        res.panel1 = @panels[1]
      # nextPanel._setOffset nextPanel._getOffset() - panel._getSize()
      # nextPanel._setSize   nextPanel._getSize() + panel._getSize()

    else if index is l - 1
      # log "LAST ONE"
      r = @resizers.pop()
      r.destroy()
      if res = @resizers[0]
        res.panel0 = @panels[l-2]
        res.panel1 = @panels[l-1]

      # prevPanel = @panels[length - 2]
      # prevPanel._setSize prevPanel._getSize() + panel._getSize()

    else
      # log "ONE IN THE MIDDLE"
      [r] = @resizers.splice index - 1, 1
      r.destroy()
      @resizers[index - 1].panel0 = @panels[index-1]
      @resizers[index - 1].panel1 = @panels[index]

      # prevPanel = @panels[index - 1]
      # prevPanel._setSize prevPanel._getSize() + panel._getSize()


    return yes

  setView:(view,index)->
    if index > @panels.length or not view
      warn "Either 'view' or 'index' is missing at KDSplitView::setView!"
      return
    @panels[index].addSubView view
