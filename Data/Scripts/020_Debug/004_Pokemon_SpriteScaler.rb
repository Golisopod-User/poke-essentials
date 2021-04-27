class EBSBitmapWrapper
  attr_reader :width
  attr_reader :height
  attr_reader :totalFrames
  attr_reader :animationFrames
  attr_reader :currentIndex
  attr_accessor :scale
  attr_reader :actualBitmap

  @@disableBitmapAnimation = false

  def initialize(file,scale = Settings::FRONT_BATTLER_SPRITE_SCALE)
    raise "filename is nil" if file.nil?
    raise ".gif files are not supported!" if File.extname(file)==".gif"

    @scale = scale
    @width = 0
    @height = 0
    @frame = 0
    @frames = 2
    @direction = +1
    @animationFinish = false
    @totalFrames = 0
    @currentIndex = 0
    @speed = 1
      # 0 - not moving at all
      # 1 - normal speed
      # 2 - medium speed
      # 3 - slow speed
    bmp = RPG::Cache.load_bitmap("",file)
    @bitmapFile = Bitmap.new(bmp.width,bmp.height); @bitmapFile.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
    bmp.dispose
    # initializes full Pokemon bitmap
    @bitmap=Bitmap.new(@bitmapFile.width,@bitmapFile.height)
    @bitmap.blt(0,0,@bitmapFile,Rect.new(0,0,@bitmapFile.width,@bitmapFile.height))
    @width=@bitmapFile.height*@scale
    @height=@bitmap.height*@scale

    @totalFrames=@bitmap.width/@bitmap.height
    @animationFrames=@totalFrames*@frames
    # calculates total number of frames
    @loop_points=[0,@totalFrames]
    # first value is start, second is end

    @actualBitmap=Bitmap.new(@width,@height)
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
  alias initialize_elite initialize unless self.method_defined?(:initialize_elite)

  def length; @totalFrames; end
  def disposed?; @actualBitmap.disposed?; end
  def dispose
    @bitmap.dispose
  @bitmapFile.dispose
    @actualBitmap.dispose
  end
  def copy; @actualBitmap.clone; end
  def bitmap; @actualBitmap; end
  def bitmap=(val); @actualBitmap=val; end
  def each; end
  def alterBitmap(index); return @strip[index]; end

  def prepareStrip
    @strip=[]
    for i in 0...@totalFrames
      bitmap=Bitmap.new(@width,@height)
      bitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmapFile,Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale))
      @strip.push(bitmap)
    end
  end
  def compileStrip
    @bitmap.clear
    for i in 0...@strip.length
      @bitmap.stretch_blt(Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale),@strip[i],Rect.new(0,0,@width,@height))
    end
  end

  def reverse
    if @direction  >  0
      @direction=-1
    elsif @direction < 0
      @direction=+1
    end
  end

  def setLoop(start, finish)
    @loop_points=[start,finish]
  end

  def setSpeed(value)
    @speed=value
  end

  def toFrame(frame)
    if frame.is_a?(String)
      if frame=="last"
        frame=@totalFrames-1
      else
        frame=0
      end
    end
    frame=@totalFrames if frame > @totalFrames
    frame=0 if frame < 0
    @currentIndex=frame
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end

  def play
    return if @currentIndex >= @loop_points[1]-1
    self.update
  end

  def finished?
    return (@currentIndex==@totalFrames-1)
  end

  def update
  return false if @@disableBitmapAnimation
    return false if @actualBitmap.disposed?
    return false if @speed < 1
    case @speed
    # frame skip
    when 1
      @frames=2
    when 2
      @frames=4
    when 3
      @frames=5
    end
    @frame+=1
    if @frame >= @frames
      # processes animation speed
      @currentIndex+=@direction
      @currentIndex=@loop_points[0] if @currentIndex >=@loop_points[1]
      @currentIndex=@loop_points[1]-1 if @currentIndex < @loop_points[0]
      @frame=0
    end
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
    # updates the actual bitmap
  end
  alias update_elite update unless self.method_defined?(:update_elite)

  # returns bitmap to original state
  def deanimate
    @frame=0
    @currentIndex=0
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
end
#===============================================================================
#  New Sprite class to utilize the animated bitmap wrappers
#===============================================================================
class EBSBitmapSprite < Sprite

  def setBitmap(file,scale=Settings::FRONT_BATTLER_SPRITE_SCALE)
    @ebsBitmap = EBSBitmapWrapper.new(file,scale)
    self.bitmap = @ebsBitmap.bitmap.clone
  end

  def setSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false)
    if species > 0
      pokemon = PokeBattle_Pokemon.new(species,5)
      @ebsBitmap = pbLoadPokemonBitmapSpecies(pokemon, species, back)
    else
      @ebsBitmap = EBSBitmapWrapper.new("Graphics/Battlers/000")
    end
    self.bitmap = @ebsBitmap.bitmap.clone
  end

  def play
    @ebsBitmap.play
    self.bitmap = @ebsBitmap.bitmap.clone
  end

  def finished?; return @ebsBitmap.finished?; end
  def ebsBitmap; return @ebsBitmap; end

  alias update_wrapper update unless self.method_defined?(:update_wrapper)
  def update
    update_wrapper
    return if @ebsBitmap.nil?
    @ebsBitmap.update
    self.bitmap = @ebsBitmap.bitmap.clone
  end

end

class AnimatedSpriteWrapper < EBSBitmapSprite; end
#===============================================================================
#  Aliases old PokemonBitmap generating functions and creates new ones,
#  utilizing the new BitmapWrapper
#===============================================================================
if !defined?(EliteBattle)
  module GameData
    class Species
      def self.front_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
        filename = self.front_sprite_filename(species, form, gender, shiny, shadow)
        return (filename) ? EBSBitmapWrapper.new(filename) : nil
      end

      def self.back_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
        filename = self.back_sprite_filename(species, form, gender, shiny, shadow)
        return (filename) ? EBSBitmapWrapper.new(filename,Settings::BACK_BATTLER_SPRITE_SCALE) : nil
      end

      def self.egg_sprite_bitmap(species, form = 0)
        filename = self.egg_sprite_filename(species, form)
        return (filename) ? EBSBitmapWrapper.new(filename) : nil
      end
    end
  end

  class PokemonPokedexInfo_Scene
    def pbUpdateDummyPokemon
      @species = @dexlist[@index][0]
      @gender  = ($Trainer.formlastseen[@species][0] rescue 0)
      @form    = ($Trainer.formlastseen[@species][1] rescue 0)
      @sprites["infosprite"].setSpeciesBitmap(@species,(@gender==1),@form)
      if @sprites["formfront"]
        @sprites["formfront"].setSpeciesBitmap(@species,(@gender==1),@form)
      end
      if @sprites["formback"]
        @sprites["formback"].setSpeciesBitmap(@species,(@gender==1),@form,false,false,true)
        @sprites["formback"].y = 256
        fSpecies = pbGetFSpeciesFromForm(@species,@form)
        @sprites["formback"].y += (pbLoadSpeciesMetrics[MetricBattlerPlayerY][fSpecies] || 0)*2
        if Settings::BACK_BATTLER_SPRITE_SCALE > Settings::FRONT_BATTLER_SPRITE_SCALE
          @sprites["formback"].zoom_x = (Settings::FRONT_BATTLER_SPRITE_SCALE/Settings::BACK_BATTLER_SPRITE_SCALE)
          @sprites["formback"].zoom_y = (Settings::FRONT_BATTLER_SPRITE_SCALE/Settings::BACK_BATTLER_SPRITE_SCALE)
        end
      end
      if @sprites["formicon"]
        @sprites["formicon"].pbSetParams(@species,@gender,@form)
      end
    end
  end

  def findTop(bitmap)
    return 0 if !bitmap
    for i in 1..bitmap.height
      for j in 0..bitmap.width-1
        return i if bitmap.get_pixel(j,bitmap.height-i).alpha>0
      end
    end
    return 0
  end

  class SpritePositioner
    def pbAutoPosition
      oldmetric1 = (@metrics[MetricBattlerPlayerY][@species] || 0)
      oldmetric3 = (@metrics[MetricBattlerEnemyY][@species] || 0)
      oldmetric4 = (@metrics[MetricBattlerAltitude][@species] || 0)
      bitmap1 = @sprites["pokemon_0"].bitmap
      bitmap2 = @sprites["pokemon_1"].bitmap
      bottom = findBottom(bitmap1)
      top = findTop(bitmap1)
      actualHeight = bottom - top
      value = actualHeight < (bitmap1.height/2) ? 5 : 3
      newmetric1 = (bitmap1.height - bottom + (bottom/value) + 1)/2
      newmetric3 = (bitmap2.height-(findBottom(bitmap2)+1))/2
      newmetric3 += 4   # Just because
      if newmetric1!=oldmetric1 || newmetric3!=oldmetric3 || oldmetric4!=0
        @metrics[MetricBattlerPlayerY][@species]  = newmetric1
        @metrics[MetricBattlerEnemyY][@species]   = newmetric3
        @metrics[MetricBattlerAltitude][@species] = 0
        @metricsChanged = true
        refresh
      end
    end
  end

  def pbAutoPositionAll
    metrics = pbLoadSpeciesMetrics
    for i in 1..PBSpecies.maxValueF
      s = pbGetSpeciesFromFSpecies(i)
      Graphics.update if i%50==0
      bitmap1 = pbLoadSpeciesBitmap(s[0],false,s[1],false,false,true)
      bitmap2 = pbLoadSpeciesBitmap(s[0],false,s[1])
      metrics[MetricBattlerPlayerX][i]    = 0   # Player's x
      if bitmap1 && bitmap1.bitmap   # Player's y
        bottom = findBottom(bitmap1.bitmap)
        top = findTop(bitmap1.bitmap)
        actualHeight = bottom - top
        value = actualHeight < (bitmap1.bitmap.height/2) ? 5 : 3
        newmetric1 = (bitmap1.bitmap.height - bottom + (bottom/value) + 1)/2
        metrics[MetricBattlerPlayerY][i]  = newmetric1
      end
      metrics[MetricBattlerEnemyX][i]     = 0   # Foe's x
      if bitmap2 && bitmap2.bitmap   # Foe's y
        metrics[MetricBattlerEnemyY][i]   = (bitmap2.height-(findBottom(bitmap2.bitmap)+1))/2
        metrics[MetricBattlerEnemyY][i]   += 4   # Just because
      end
      metrics[MetricBattlerAltitude][i]   = 0   # Foe's altitude, not used now
      metrics[MetricBattlerShadowX][i]    = 0   # Shadow's x
      metrics[MetricBattlerShadowSize][i] = 2   # Shadow size
      bitmap1.dispose if bitmap1
      bitmap2.dispose if bitmap2
    end
    save_data(metrics,"Data/species_metrics.dat")
    $PokemonTemp.speciesMetrics = nil
    pbSavePokemonData
    pbSavePokemonFormsData
  end
end
