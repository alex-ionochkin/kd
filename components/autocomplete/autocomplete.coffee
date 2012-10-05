class KDAutoComplete extends KDInputView
  mouseDown: ->
    @focus()

  setDomElement:->
    @domElement = $ "<div class='kdautocompletewrapper clearfix'><input type='text' class='kdinput text'/></div>"

  setDomId:()->
    @$input().attr "id",@getDomId()
    @$input().attr "name",@getName()
    @$input().data "data-id",@getId()

  setDefaultValue:(value) ->
    @inputDefaultValue = value
    @setValue value

  $input:()->@$().find("input").eq(0)
  getValue:()-> @$input().val()
  setValue:(value)-> @$input().val(value)

  bindEvents:()->
    super @$input()

  # FIX THIS: on blur dropdown should disappear but the
  # problem is if you the lines below, blur fires earlier than
  # KDAutoCompleteListItemViewClick and that breaks mouse selection
  # on autocomplete list
  blur:(pubInst,event)->
    @unsetClass "focus"
    # @hideDropdown()
    # log pubInst,event.target,"blur"
    # @destroyDropdown()

  focus:(pubInst,event)->
    @setClass "focus"
    (@getSingleton "windowController").setKeyView @

  keyDown:(event)->
    (@getSingleton "windowController").setKeyView @
    switch event.which
      when 13, 27, 38, 40 #enter, escape, up, down
        no
      else yes

  getLeftOffset:()->
    @$input().prev().width()

  destroyDropdown:()->
    @removeSubView @dropdown if @dropdown?
    @dropdownPrefix = ""
    @dropdown = null