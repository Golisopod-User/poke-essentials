class Pokemon
  #=============================================================================
  # Mega Evolution
  # NOTE: These are treated as form changes in Essentials.
  #=============================================================================
  def getMegaForm(checkItemOnly = false)
    ret = 0
    GameData::Species.each do |data|
      next if data.species != @species
      if data.mega_stone && hasItem?(data.mega_stone)
        ret = data.form
        break
      elsif !checkItemOnly && data.mega_move && hasMove?(data.mega_move)
        ret = data.form
        break
      end
    end
    ret = getSpecificMegaForm if hasSpecificMegaForm?
    return ret   # form number, or 0 if no accessible Mega form
  end

  def getUnmegaForm
    ret = -1
    if mega?
      ret = species_data.unmega_form
      ret = getSpecificUnmegaForm if hasSpecificUnmegaForm?
    end
    return ret
  end

  def hasMegaForm?
    megaForm = self.getMegaForm
    return megaForm > 0 && megaForm != form_simple
  end

  def mega?
    megaForm = self.getMegaForm
    return megaForm > 0 && megaForm == form_simple
  end

  def makeMega
    megaForm = self.getMegaForm
    self.form = megaForm if megaForm > 0
  end

  def makeUnmega
    unmegaForm = self.getUnmegaForm
    self.form = unmegaForm if unmegaForm >= 0
  end

  def megaName
    formName = species_data.form_name
    return (formName && !formName.empty?) ? formName : _INTL("Mega {1}", species_data.name)
  end

  def megaMessage   # 0=default message, 1=Rayquaza message
    return species_data.mega_message
  end

  #=============================================================================
  # Primal Reversion
  # NOTE: These are treated as form changes in Essentials.
  #=============================================================================
  def hasPrimalForm?
    v = MultipleForms.call("getPrimalForm", self)
    return !v.nil?
  end

  def primal?
    v = MultipleForms.call("getPrimalForm", self)
    return !v.nil? && v == @form
  end

  def makePrimal
    v = MultipleForms.call("getPrimalForm", self)
    self.form = v if !v.nil?
  end

  def makeUnprimal
    v = MultipleForms.call("getUnprimalForm", self)
    if !v.nil?;    self.form = v
    elsif primal?; self.form = 0
    end
  end
end

#===============================================================================
# Form Specific Mega Evolution
# To prevent Galarian Slowbro from Mega Evolving
#===============================================================================
class Pokemon
  def hasSpecificMegaForm?
    v = MultipleForms.call("getSpecificMegaForm",self)
    return !v.nil?
  end

  def getSpecificMegaForm
    v = MultipleForms.call("getSpecificMegaForm",self)
    return v if v.is_a?(Numeric)
  end

  def hasSpecificUnmegaForm?
    v = MultipleForms.call("getSpecificUnmegaForm",self)
    return !v.nil?
  end

  def getSpecificUnmegaForm
    v = MultipleForms.call("getSpecificUnmegaForm",self)
    v = self.form if !v || v<0
    return v if v.is_a?(Numeric)
  end
end
