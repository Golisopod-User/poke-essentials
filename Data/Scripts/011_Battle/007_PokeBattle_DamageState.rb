class PokeBattle_DamageState
  attr_accessor :initialHP
  attr_accessor :typeMod         # Type effectiveness
  attr_accessor :unaffected
  attr_accessor :protected
  attr_accessor :magicCoat
  attr_accessor :magicBounce
  attr_accessor :totalHPLost     # Like hpLost, but cumulative over all hits
  attr_accessor :fainted         # Whether battler was knocked out by the move

  attr_accessor :missed          # Whether the move failed the accuracy check
  attr_accessor :calcDamage      # Calculated damage
  attr_accessor :hpLost          # HP lost by opponent, inc. HP lost by a substitute
  attr_accessor :critical        # Critical hit flag
  attr_accessor :substitute      # Whether a substitute took the damage
  attr_accessor :focusBand       # Focus Band used
  attr_accessor :focusSash       # Focus Sash used
  attr_accessor :sturdy          # Sturdy ability used
  attr_accessor :disguise        # Disguise ability used
  attr_accessor :endured         # Damage was endured
  attr_accessor :berryWeakened   # Whether a type-resisting berry was used
  attr_accessor :iceface         # Ice Face ability used

  def initialize; reset; end

  def reset
    @initialHP          = 0
    @typeMod            = Effectiveness::INEFFECTIVE
    @unaffected         = false
    @protected          = false
    @magicCoat          = false
    @magicBounce        = false
    @totalHPLost        = 0
    @fainted            = false
    resetPerHit
  end

  def resetPerHit
    @missed        = false
    @calcDamage    = 0
    @hpLost        = 0
    @critical      = false
    @substitute    = false
    @focusBand     = false
    @focusSash     = false
    @sturdy        = false
    @disguise      = false
    @endured       = false
    @berryWeakened = false
    @iceface       = false
  end
end



################################################################################
# Success state (used for Battle Arena)
################################################################################
class PokeBattle_SuccessState
  attr_accessor :typeMod
  attr_accessor :useState    # 0 - not used, 1 - failed, 2 - succeeded
  attr_accessor :protected
  attr_accessor :skill

  def initialize; clear; end

  def clear(full=true)
    @typeMod   = Effectiveness::NORMAL_EFFECTIVE
    @useState  = 0
    @protected = false
    @skill     = 0 if full
  end

  def updateSkill
    if @useState==1
      @skill = -2 if !@protected
    elsif @useState==2
      if Effectiveness.super_effective?(@typeMod);       @skill = 2
      elsif Effectiveness.normal?(@typeMod);             @skill = 1
      elsif Effectiveness.not_very_effective?(@typeMod); @skill = -1
      else;                                              @skill = -2   # Ineffective
      end
    end
    clear(false)
  end
end
