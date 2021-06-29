#===============================================================================
#
#===============================================================================
class PokemonPokedexInfo_Scene
  def pbStartScene(dexlist,index,region)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @dexlist = dexlist
    @index   = index
    @region  = region
    @page = 1
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_types"))
    @sprites = {}
    # Defines the Scrolling Background, as well as the overlay on top of it
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"] = ScrollingSprite.new(@viewport)
    @sprites["background"].speed = 1
    @sprites["infoverlay"] = IconSprite.new(0,0,@viewport)
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::Center)
    # Changes the postion of the Pokémon in the Entry Page
    @sprites["infosprite"].x = 98
    @sprites["infosprite"].y = 112
    @mapdata = pbLoadTownMapData
    map_metadata = GameData::MapMetadata.try_get($game_map.map_id)
    mappos = (map_metadata) ? map_metadata.town_map_position : nil
    if @region < 0                                 # Use player's current region
      @region = (mappos) ? mappos[0] : 0                      # Region 0 default
    end
    @sprites["areamap"] = IconSprite.new(0,0,@viewport)
    @sprites["areamap"].setBitmap("Graphics/Pictures/#{@mapdata[@region][1]}")
    @sprites["areamap"].x += (Graphics.width-@sprites["areamap"].bitmap.width)/2
    @sprites["areamap"].y += (Graphics.height+16-@sprites["areamap"].bitmap.height)/2
    for hidden in Settings::REGION_MAP_EXTRAS
      if hidden[0]==@region && hidden[1]>0 && $game_switches[hidden[1]]
       pbDrawImagePositions(@sprites["areamap"].bitmap,[
          ["Graphics/Pictures/#{hidden[4]}",
             hidden[2]*PokemonRegionMap_Scene::SQUAREWIDTH,
             hidden[3]*PokemonRegionMap_Scene::SQUAREHEIGHT]
       ])
      end
    end
    @sprites["areahighlight"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["areaoverlay"] = IconSprite.new(0,0,@viewport)
    @sprites["areaoverlay"].setBitmap("Graphics/Pictures/Pokedex/overlay_area")
    @sprites["formfront"] = PokemonSprite.new(@viewport)
    @sprites["formfront"].setOffset(PictureOrigin::Center)
    # Changes the X and Y position of the front sprite of the Pokémon in the
    # Forms Page
    @sprites["formfront"].x = 382
    @sprites["formfront"].y = 240
    @sprites["formback"] = PokemonSprite.new(@viewport)
    @sprites["formback"].setOffset(PictureOrigin::Center)
    # Changes the X position of the back sprite of the Pokémon in the Forms Page
    @sprites["formback"].x = 124
    @sprites["formicon"] = PokemonSpeciesIconSprite.new(nil, @viewport)
    @sprites["formicon"].setOffset(PictureOrigin::Center)
    # Changes the X and Y position of the icon sprite of the Pokémon in the
    # Forms Page
    @sprites["formicon"].x = 64
    @sprites["formicon"].y = 112
    # Changes the X and Y position of the Up Arrow sprite of the Pokémon in the
    # Forms Page
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["uparrow"].x = 242
    @sprites["uparrow"].y = 40
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    # Changes the X and Y position of the Down Arrow sprite of the Pokémon in the
    # Forms Page
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 242
    @sprites["downarrow"].y = 128
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    @available = pbGetAvailableForms
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartSceneBrief(species)  # For standalone access, shows first page only
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    dexnum = 0
    dexnumshift = false
    if $Trainer.pokedex.unlocked?(-1)   # National Dex is unlocked
      species_data = GameData::Species.try_get(species)
      dexnum = species_data.id_number if species_data
      dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(-1)
    else
      dexnum = 0
      for i in 0...$Trainer.pokedex.dexes_count - 1   # Regional Dexes
        next if !$Trainer.pokedex.unlocked?(i)
        num = pbGetRegionalNumber(i,species)
        next if num <= 0
        dexnum = num
        dexnumshift = true if Settings::DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    @dexlist = [[species,"",0,0,dexnum,dexnumshift]]
    @index   = 0
    @page = 1
    @brief = true
    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_types"))
    @sprites = {}
    # Defines the Scrolling Background of the Entry Scene when capturing a Wild
    # Pokémon, as well as the overlay on top of it
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"] = ScrollingSprite.new(@viewport)
    @sprites["background"].speed = 1
    @sprites["infoverlay"] = IconSprite.new(0,0,@viewport)
    @sprites["capturebar"] = IconSprite.new(0,0,@viewport)
    @sprites["infosprite"] = PokemonSprite.new(@viewport)
    @sprites["infosprite"].setOffset(PictureOrigin::Center)
    # Changes the X and Y position of the front sprite of the Pokémon in the  Entry
    # Scene when capturing a Wild Pokémon
    @sprites["infosprite"].x = 98
    @sprites["infosprite"].y = 136
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbUpdateDummyPokemon
    drawPage(@page)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbUpdateDummyPokemon
    @species = @dexlist[@index][0]
    @gender, @form = $Trainer.pokedex.last_form_seen(@species)
    species_data = GameData::Species.get_species_form(@species, @form)
    @sprites["infosprite"].setSpeciesBitmap(@species,@gender,@form)
    if @sprites["formfront"]
      @sprites["formfront"].setSpeciesBitmap(@species,@gender,@form)
    end
    if @sprites["formback"]
      @sprites["formback"].setSpeciesBitmap(@species,@gender,@form,false,false,true)
      # This one was a bit hard to find, but it changes the Y position of the
      # backsprite of the Pokémon in the Forms Page
      @sprites["formback"].y = 226
      if defined?(Essentials::GEN_8_VERSION)
        @sprites["formback"].setOffset(PictureOrigin::Center)
        @sprites["formback"].y = @sprites["formfront"].y if @sprites["formfront"]
        if Settings::BACK_BATTLER_SPRITE_SCALE > Settings::FRONT_BATTLER_SPRITE_SCALE
          @sprites["formback"].zoom_x = ((Settings::FRONT_BATTLER_SPRITE_SCALE * 1.0)/Settings::BACK_BATTLER_SPRITE_SCALE)
          @sprites["formback"].zoom_y = ((Settings::FRONT_BATTLER_SPRITE_SCALE * 1.0)/Settings::BACK_BATTLER_SPRITE_SCALE)
        end
      end
    end
    if @sprites["formicon"]
      @sprites["formicon"].pbSetParams(@species,@gender,@form)
    end
  end

  def drawPageInfo
    # Sets the Scrolling Background of the Entry Page, as well as the overlay on
    # top of it
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_info"))
    @sprites["infoverlay"].setBitmap(_INTL("Graphics/Pictures/Pokedex/info_overlay"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(82, 82, 90)
    shadow = Color.new(165, 165, 173)
    imagepos = []
    if @brief
      # Sets the Scrolling Background of the Entry Scena when capturing a wild Pokémon,
      # as well as the overlay on top of it
      @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_capture"))
      @sprites["infoverlay"].setBitmap(_INTL("Graphics/Pictures/Pokedex/capture_overlay"))
      @sprites["capturebar"].setBitmap(_INTL("Graphics/Pictures/Pokedex/overlay_info"))
    end
    species_data = GameData::Species.get_species_form(@species, @form)
    # Write various bits of text
    indexText = "???"
    if @dexlist[@index][4] > 0
      indexNumber = @dexlist[@index][4]
      indexNumber -= 1 if @dexlist[@index][5]
      indexText = sprintf("%03d", indexNumber)
    end
    # This bit of the code woudn't have been possible without the help of NettoHikari.
    # He helped me to set the Sprites and Texts differently, depending on if the
    # Pokédex Entry Scene is playing, when the payer is capturing a Wild Pokémon,
    # or if the player is seeing the "normal" Dex Entry page on the Pokédex.
    #
    # Basically, this next lines changes the position of various text
    # (height, weight, the Name's Species, etc), depending on if the
    # Pokédex Entry Scene is playing, when the payer is capturing a Wild Pokémon,
    # or if the player is seeing the "normal" Dex Entry page on the Pokédex.
    if @brief
      textpos = [
        [_INTL("Pokémon Registration Complete"), 82, -2, 0, Color.new(255, 255, 255), Color.new(165, 165, 173)],
        [_INTL("{1}{2} {3}", indexText, " ", species_data.name),
           272, 54, 0, Color.new(82, 82, 90), Color.new(165, 165, 173)],
        [_INTL("Height"), 288, 170, 0, base, shadow],
        [_INTL("Weight"), 288, 200, 0, base, shadow]
      ]
    else
      textpos = [[_INTL("{1}{2} {3}", indexText, " ", species_data.name),
         272, 16, 0, Color.new(82, 82, 90), Color.new(165, 165, 173)]]
      if !@checkingNumberBattled
        textpos.push([_INTL("Height"), 288, 132, 0, base, shadow])
        textpos.push([_INTL("Weight"), 288, 162, 0, base, shadow])
      else
        textpos.push([_INTL("Number Battled:"), 288, 132, 0, base, shadow])
      end
    end
    if $Trainer.owned?(@species)
      # Write the category. Changed
      if @brief
        textpos.push([_INTL("{1} Pokémon", species_data.category), 376, 90, 2, base, shadow])
      else
        textpos.push([_INTL("{1} Pokémon", species_data.category), 376, 52, 2, base, shadow])
      end
      if !@checkingNumberBattled
        # Write the height and weight. Changed
        height = species_data.height
        weight = species_data.weight
        if System.user_language[3..4] == "US"   # If the user is in the United States
          inches = (height / 0.254).round
          pounds = (weight / 0.45359).round
          if @brief
            textpos.push([_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12), 490, 170, 1, base, shadow])
            textpos.push([_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0), 490, 200, 1, base, shadow])
          else
            textpos.push([_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12), 490, 132, 1, base, shadow])
            textpos.push([_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0), 490, 162, 1, base, shadow])
          end
        else
          if @brief
            textpos.push([_ISPRINTF("{1:.1f} m", height / 10.0), 490, 170, 1, base, shadow])
            textpos.push([_ISPRINTF("{1:.1f} kg", weight / 10.0), 490, 200, 1, base, shadow])
          else
            textpos.push([_ISPRINTF("{1:.1f} m", height / 10.0), 490, 132, 1, base, shadow])
            textpos.push([_ISPRINTF("{1:.1f} kg", weight / 10.0), 490, 162, 1, base, shadow])
          end
        end
      else
        textpos.push([(_ISPRINTF("{1:03d}",$Trainer.pokedex.number_battled(@species))), 490, 162, 1, base, shadow])
      end
      # Draw the Pokédex entry text. Changed
      base   = Color.new(255,255,255)
      shadow = Color.new(165,165,173)
      if @brief
        drawTextEx(overlay, 38, 258, Graphics.width - (40 * 2), 4,   # overlay, x, y, width, num lines
          species_data.pokedex_entry, base, shadow)
      else
        drawTextEx(overlay, 38, 220, Graphics.width - (40 * 2), 4,   # overlay, x, y, width, num lines
          species_data.pokedex_entry, base, shadow)
      end
      # Draw the footprint. Changed
      footprintfile = GameData::Species.footprint_filename(@species, @form)
      if footprintfile
        footprint = RPG::Cache.load_bitmap("",footprintfile)
        if @brief
          overlay.blt(224, 150, footprint, footprint.rect)
        else
          overlay.blt(224, 112, footprint, footprint.rect)
        end
        footprint.dispose
      end
      # Show the owned icon. Changed
      if @brief
        imagepos.push(["Graphics/Pictures/Pokedex/icon_own", 210, 57])
      else
        imagepos.push(["Graphics/Pictures/Pokedex/icon_own", 210, 19])
      end
      # Draw the type icon(s). Changed
      type1 = species_data.type1
      type2 = species_data.type2
      type1_number = GameData::Type.get(type1).id_number
      type2_number = GameData::Type.get(type2).id_number
      type1rect = Rect.new(0, type1_number * 32, 96, 32)
      type2rect = Rect.new(0, type2_number * 32, 96, 32)
      if @brief
        overlay.blt(286, 132, @typebitmap.bitmap, type1rect)
        overlay.blt(366, 132, @typebitmap.bitmap, type2rect) if type1 != type2
      else
        overlay.blt(286, 94, @typebitmap.bitmap, type1rect)
        overlay.blt(366, 94, @typebitmap.bitmap, type2rect) if type1 != type2
      end
    else
      # This bit of the code below is simply the Entry Page when you have seen the
      # Pokémon, but did'nt capture it yet.
      # Write the category. Changed
      textpos.push([_INTL("????? Pokémon"), 274, 50, 0, base, shadow])
      # Write the height and weight. Changed
      if !@checkingNumberBattled
        if System.user_language[3..4] == "US"   # If the user is in the United States
          textpos.push([_INTL("???'??\""), 490, 136, 1, base, shadow])
          textpos.push([_INTL("????.? lbs."), 488, 170, 1, base, shadow])
        else
          textpos.push([_INTL("????.? m"), 488, 132, 1, base, shadow])
          textpos.push([_INTL("????.? kg"), 488, 162, 1, base, shadow])
        end
      else
        textpos.push([_INTL("???"), 488, 162, 1, base, shadow])
      end
    end
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    # Draw all images
    pbDrawImagePositions(overlay, imagepos)
  end

  def drawPageArea
    # Sets the Scrolling Background of the Area Page, as well as the overlay on top of it
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_area"))
    @sprites["infoverlay"].setBitmap(_INTL("Graphics/Pictures/Pokedex/map_overlay"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(88,88,80)
    shadow = Color.new(168,184,184)
    @sprites["areahighlight"].bitmap.clear
    # Fill the array "points" with all squares of the region map in which the
    # species can be found
    points = []
    mapwidth = 1+PokemonRegionMap_Scene::RIGHT-PokemonRegionMap_Scene::LEFT
    GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
      next if !pbFindEncounter(enc_data.types, @species)
      map_metadata = GameData::MapMetadata.try_get(enc_data.map)
      mappos = (map_metadata) ? map_metadata.town_map_position : nil
      next if !mappos || mappos[0] != @region
      showpoint = true
      for loc in @mapdata[@region][2]
        showpoint = false if loc[0]==mappos[1] && loc[1]==mappos[2] &&
                            loc[7] && !$game_switches[loc[7]]
      end
      next if !showpoint
      mapsize = map_metadata.town_map_size
      if mapsize && mapsize[0] && mapsize[0]>0
        sqwidth  = mapsize[0]
        sqheight = (mapsize[1].length*1.0/mapsize[0]).ceil
        for i in 0...sqwidth
          for j in 0...sqheight
            if mapsize[1][i+j*sqwidth,1].to_i>0
              points[mappos[1]+i+(mappos[2]+j)*mapwidth] = true
            end
          end
        end
      else
        points[mappos[1]+mappos[2]*mapwidth] = true
      end
    end
    # Draw coloured squares on each square of the region map with a nest
    pointcolor   = Color.new(0,248,248)
    pointcolorhl = Color.new(192,248,248)
    sqwidth = PokemonRegionMap_Scene::SQUAREWIDTH
    sqheight = PokemonRegionMap_Scene::SQUAREHEIGHT
    for j in 0...points.length
      if points[j]
        x = (j%mapwidth)*sqwidth
        x += (Graphics.width-@sprites["areamap"].bitmap.width)/2
        y = (j/mapwidth)*sqheight
        y += (Graphics.height+16-@sprites["areamap"].bitmap.height)/2
        @sprites["areahighlight"].bitmap.fill_rect(x,y,sqwidth,sqheight,pointcolor)
        if j-mapwidth<0 || !points[j-mapwidth]
          @sprites["areahighlight"].bitmap.fill_rect(x,y-2,sqwidth,2,pointcolorhl)
        end
        if j+mapwidth>=points.length || !points[j+mapwidth]
          @sprites["areahighlight"].bitmap.fill_rect(x,y+sqheight,sqwidth,2,pointcolorhl)
        end
        if j%mapwidth==0 || !points[j-1]
          @sprites["areahighlight"].bitmap.fill_rect(x-2,y,2,sqheight,pointcolorhl)
        end
        if (j+1)%mapwidth==0 || !points[j+1]
          @sprites["areahighlight"].bitmap.fill_rect(x+sqwidth,y,2,sqheight,pointcolorhl)
        end
      end
    end
    # Set the text
    # Changes the color of the text, to the one used in BW
    base   = Color.new(255,255,255)
    shadow = Color.new(165,165,173)
    textpos = []
    if points.length==0
      pbDrawImagePositions(overlay,[
        [sprintf("Graphics/Pictures/Pokedex/overlay_areanone"),108,148]
      ])
      textpos.push([_INTL("Area unknown"),Graphics.width/2,146,2,base,shadow])
    end
    # Minor changes to the color of the text, to mimic the one used in BW
    textpos.push([pbGetMessage(MessageTypes::RegionNames,@region),58,0,0,Color.new(255,255,255),Color.new(115,115,115)])
    textpos.push([_INTL("{1}'s area",GameData::Species.get(@species).name),
      Graphics.width/1.4,0,2,Color.new(255,255,255),Color.new(115,115,115)])
    pbDrawTextPositions(overlay,textpos)
  end

  def drawPageForms
    # Sets the Scrolling Background of the Forms Page, as well as the overlay on top of it
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_forms"))
    @sprites["infoverlay"].setBitmap(_INTL("Graphics/Pictures/Pokedex/forms_overlay"))
    overlay = @sprites["overlay"].bitmap
    # Changes the color of the text, to the one used in BW
    base   = Color.new(255,255,255)
    shadow = Color.new(165,165,173)
    # Write species and form name
    formname = ""
    for i in @available
      if i[1]==@gender && i[2]==@form
        formname = i[0]; break
      end
    end
    textpos = [
      [_INTL("Forms"),58,0,0,Color.new(255,255,255),Color.new(115,115,115)],
      [GameData::Species.get(@species).name,Graphics.width/2,Graphics.height-316,2,base,shadow],
      [formname,Graphics.width/2,Graphics.height-280,2,base,shadow],
    ]
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
  end
end
