#===============================================================================
# Box
#===============================================================================
class PokemonBoxSprite < SpriteWrapper
  attr_accessor :refreshBox
  attr_accessor :refreshSprites

  def initialize(storage,boxnumber,viewport=nil)
    super(viewport)
    @storage = storage
    @boxnumber = boxnumber
    @refreshBox = true
    @refreshSprites = true
    @pokemonsprites = []
    for i in 0...PokemonBox::BOX_SIZE
      @pokemonsprites[i] = nil
      pokemon = @storage[boxnumber,i]
      @pokemonsprites[i] = PokemonBoxIcon.new(pokemon,viewport)
    end
    @contents = BitmapWrapper.new(324,302)
    self.bitmap = @contents
    self.x = 190
    self.y = 18
    refresh
  end

  def refresh
    if @refreshBox
      boxname = @storage[@boxnumber].name
      getBoxBitmap
	  # Changed Box Height by a few pixels
      @contents.blt(0,0,@boxbitmap.bitmap,Rect.new(0,0,324,302))
      pbSetSystemFont(@contents)
      widthval = @contents.text_size(boxname).width
	  # Changed X Postiont of Box Name 
      xval = 163-(widthval/2)
	  # Changed color of Box Name
      pbDrawShadowText(@contents,xval,8,widthval,28,
         boxname,Color.new(41,41,41),Color.new(132,132,132))
      @refreshBox = false
    end
	# Changed position of Pokémon Icons inside the box
    yval = self.y+36
    for j in 0...PokemonBox::BOX_HEIGHT
      xval = self.x+10
      for k in 0...PokemonBox::BOX_WIDTH
        sprite = @pokemonsprites[j * PokemonBox::BOX_WIDTH + k]
        if sprite && !sprite.disposed?
          sprite.viewport = self.viewport
          sprite.x = xval
          sprite.y = yval
          sprite.z = 0
        end
        xval += 48
      end
      yval += 48
    end
  end
end

#===============================================================================
# Party pop-up panel
#===============================================================================
class PokemonBoxPartySprite < SpriteWrapper
  def refresh
    @contents.blt(0, 0, @boxbitmap.bitmap, Rect.new(0, 0, 172, 352))
    pbDrawTextPositions(self.bitmap,[
	# Changed position of Back Menu
       [_INTL("Back"), 86, 236, 2, Color.new(239,239,239), Color.new(132,132,132),0]
    ])
    xvalues = []   # [18, 90, 18, 90, 18, 90]
    yvalues = []   # [2, 18, 66, 82, 130, 146]
    for i in 0...Settings::MAX_PARTY_SIZE
      xvalues.push(18 + 72 * (i % 2))
      yvalues.push(2 + 16 * (i % 2) + 64 * (i / 2))
    end
    for j in 0...Settings::MAX_PARTY_SIZE
      @pokemonsprites[j] = nil if @pokemonsprites[j] && @pokemonsprites[j].disposed?
    end
    @pokemonsprites.compact!
    for j in 0...Settings::MAX_PARTY_SIZE
      sprite = @pokemonsprites[j]
      if sprite && !sprite.disposed?
        sprite.viewport = self.viewport
        sprite.x = self.x + xvalues[j]
        sprite.y = self.y + yvalues[j]
        sprite.z = 0
      end
    end
  end
end

#===============================================================================
# Pokémon storage visuals
#===============================================================================
class PokemonStorageScene
  attr_reader :quickswap

  def pbStartBox(screen,command)
    @screen = screen
    @storage = screen.storage
    @bgviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @bgviewport.z = 99999
    @boxviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @boxviewport.z = 99999
    @boxsidesviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @boxsidesviewport.z = 99999
    @arrowviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @arrowviewport.z = 99999
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @selection = 0
    @quickswap = false
    @sprites = {}
    @choseFromParty = false
    @command = command
    addBackgroundPlane(@sprites,"background","Storage/bg",@bgviewport)
    @sprites["box"] = PokemonBoxSprite.new(@storage,@storage.currentBox,@boxviewport)
    @sprites["boxsides"] = IconSprite.new(0,0,@boxsidesviewport)
    @sprites["boxsides"].setBitmap("Graphics/Pictures/Storage/overlay_main")
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@boxsidesviewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["pokemon"] = AutoMosaicPokemonSprite.new(@boxsidesviewport)
    @sprites["pokemon"].setOffset(PictureOrigin::Center)
	# Changed Position of Pokémon Battler
    @sprites["pokemon"].x = 98
    @sprites["pokemon"].y = 148
    @sprites["boxparty"] = PokemonBoxPartySprite.new(@storage.party,@boxsidesviewport)
    if command!=2   # Drop down tab only on Deposit
      @sprites["boxparty"].x = 182
      @sprites["boxparty"].y = Graphics.height
    end
    @markingbitmap = AnimatedBitmap.new("Graphics/Pictures/Storage/markings")
    @sprites["markingbg"] = IconSprite.new(292,68,@boxsidesviewport)
    @sprites["markingbg"].setBitmap("Graphics/Pictures/Storage/overlay_marking")
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@boxsidesviewport)
    @sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["arrow"] = PokemonBoxArrow.new(@arrowviewport)
    @sprites["arrow"].z += 1
    if command!=2
      pbSetArrow(@sprites["arrow"],@selection)
      pbUpdateOverlay(@selection)
      pbSetMosaic(@selection)
    else
      pbPartySetArrow(@sprites["arrow"],@selection)
      pbUpdateOverlay(@selection,@storage.party)
      pbSetMosaic(@selection)
    end
    pbSEPlay("PC access")
    pbFadeInAndShow(@sprites)
  end

  def pbSwitchBoxToRight(newbox)
    newbox = PokemonBoxSprite.new(@storage,newbox,@boxviewport)
    newbox.x = 520
    Graphics.frame_reset
    distancePerFrame = 64*20/Graphics.frame_rate
    loop do
      Graphics.update
      Input.update
      @sprites["box"].x -= distancePerFrame
      newbox.x -= distancePerFrame
      self.update
	  # Changed position of new Box (when moving)
      break if newbox.x<=190
    end
	# Changed position of new Box (when moving)
    diff = newbox.x-190
    newbox.x = 190
    @sprites["box"].x -= diff
    @sprites["box"].dispose
    @sprites["box"] = newbox
  end

  def pbSwitchBoxToLeft(newbox)
    newbox = PokemonBoxSprite.new(@storage,newbox,@boxviewport)
    newbox.x = -152
    Graphics.frame_reset
    distancePerFrame = 64*20/Graphics.frame_rate
    loop do
      Graphics.update
      Input.update
      @sprites["box"].x += distancePerFrame
      newbox.x += distancePerFrame
      self.update
	  # Changed position of new Box (when moving)
      break if newbox.x>=190
    end
	# Changed position of new Box (when moving)
    diff = newbox.x-190
    newbox.x = 190
    @sprites["box"].x -= diff
    @sprites["box"].dispose
    @sprites["box"] = newbox
  end

  def pbMarkingSetArrow(arrow,selection)
    if selection>=0
      xvalues = [162,191,220,162,191,220,190,190]
      yvalues = [24,24,24,49,49,49,77,109]
      arrow.angle = 0
      arrow.mirror = false
      arrow.ox = 0
      arrow.oy = 0
      arrow.x = xvalues[selection]*2
      arrow.y = yvalues[selection]*2
    end
  end

  def pbMark(selected,heldpoke)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    msg = _INTL("Mark your Pokémon.")
    msgwindow = Window_UnformattedTextPokemon.newWithSize("",180,0,Graphics.width-180,32)
    msgwindow.viewport       = @viewport
    msgwindow.visible        = true
    msgwindow.letterbyletter = false
    msgwindow.text           = msg
    msgwindow.resizeHeightToFit(msg,Graphics.width-180)
    pbBottomRight(msgwindow)
    base   = Color.new(248,248,248)
    shadow = Color.new(80,80,80)
    pokemon = heldpoke
    if heldpoke
      pokemon = heldpoke
    elsif selected[0]==-1
      pokemon = @storage.party[selected[1]]
    else
      pokemon = @storage.boxes[selected[0]][selected[1]]
    end
    markings = pokemon.markings
    index = 0
    redraw = true
    markrect = Rect.new(0,0,16,16)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        for i in 0...6
          markrect.x = i*16
          markrect.y = (markings&(1<<i)!=0) ? 16 : 0
          @sprites["markingoverlay"].bitmap.blt(336+58*(i%3),106+50*(i/3),@markingbitmap.bitmap,markrect)
        end
        textpos = [
           [_INTL("OK"),402,204,2,Color.new(239,239,239),Color.new(132,132,132),0],
           [_INTL("Cancel"),402,268,2,Color.new(239,239,239),Color.new(132,132,132),0]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap,textpos)
        pbMarkingSetArrow(@sprites["arrow"],index)
        redraw = false
      end
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key>=0
        oldindex = index
        index = pbMarkingChangeSelection(key,index)
        pbPlayCursorSE if index!=oldindex
        pbMarkingSetArrow(@sprites["arrow"],index)
      end
      self.update
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        if index==6   # OK
          pokemon.markings = markings
          break
        elsif index==7   # Cancel
          break
        else
          mask = (1<<index)
          if (markings&mask)==0
            markings |= mask
          else
            markings &= ~mask
          end
          redraw = true
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    msgwindow.dispose
  end

  def pbUpdateOverlay(selection,party=nil)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
	# Changed text color
    buttonbase = Color.new(239,239,239)
    buttonshadow = Color.new(132,132,132)
    pbDrawTextPositions(overlay,[
       [_INTL("PARTY: {1}",(@storage.party.length rescue 0)),274,338,2,buttonbase,buttonshadow],
       [_INTL("Exit"),450,338,2,buttonbase,buttonshadow],
    ])
    pokemon = nil
    if @screen.pbHeldPokemon
      pokemon = @screen.pbHeldPokemon
    elsif selection>=0
      pokemon = (party) ? party[selection] : @storage[@storage.currentBox,selection]
    end
    if !pokemon
      @sprites["pokemon"].visible = false
      return
    end
    @sprites["pokemon"].visible = true
    # Changed text color
    base   = Color.new(90,82,82)
    shadow = Color.new(165,165,173)
    nonbase   = Color.new(90,82,82)
    nonshadow = Color.new(165,165,173)
    pokename = pokemon.name
    textstrings = [
	# Changed text position
       [pokename,10,4,false,base,shadow]
    ]
    if !pokemon.egg?
      imagepos = []
      if pokemon.male?
        textstrings.push([_INTL("♂"),148,4,false,Color.new(0,0,214),Color.new(15,148,255)])
      elsif pokemon.female?
        textstrings.push([_INTL("♀"),148,4,false,Color.new(198,0,0),Color.new(255,155,155)])
      end
      imagepos.push(["Graphics/Pictures/Storage/overlay_lv",6,268])
      textstrings.push([pokemon.level.to_s,28,250,false,Color.new(255,255,255),Color.new(90,82,82)])
      if pokemon.ability
        textstrings.push([pokemon.ability.name,16,316,0,base,shadow])
      else
        textstrings.push([_INTL("No ability"),16,316,0,nonbase,nonshadow])
      end
      if pokemon.item
        textstrings.push([pokemon.item.name,16,348,0,base,shadow])
      else
        textstrings.push([_INTL("No item"),16,348,0,nonbase,nonshadow])
      end
      if pokemon.shiny?
        imagepos.push(["Graphics/Pictures/shiny",68,262])
      end
      typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
      type1_number = GameData::Type.get(pokemon.type1).id_number
      type2_number = GameData::Type.get(pokemon.type2).id_number
      type1rect = Rect.new(0, type1_number * 28, 64, 28)
      type2rect = Rect.new(0, type2_number * 28, 64, 28)
      if pokemon.type1==pokemon.type2
	  # Changed Pokémon Type Icon position
        overlay.blt(62,292,typebitmap.bitmap,type1rect)
      else
	  # Changed Pokémon Type Icon position
        overlay.blt(26,292,typebitmap.bitmap,type1rect)
        overlay.blt(96,292,typebitmap.bitmap,type2rect)
      end
	  # Changed Markings position
      drawMarkings(overlay,86,262,128,20,pokemon.markings)
      pbDrawImagePositions(overlay,imagepos)
    end
    pbDrawTextPositions(overlay,textstrings)
    @sprites["pokemon"].setPokemonBitmap(pokemon)
  end
end