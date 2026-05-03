local constants = require("MistyStep.constants")
local log = require("MistyStep.log")
local blink = require("MistyStep.blink")

require("MistyStep.effects")

event.register(tes3.event.initialized, function()
    local spell = tes3.getObject(constants.SPELL_ID)
    if not spell then
        spell = tes3.createObject({
            id = constants.SPELL_ID,
            objectType = tes3.objectType.spell
        })
        tes3.setSourceless(spell)
        spell.name = "Misty Step"
        spell.magickaCost = constants.MAGICKA_COST

        spell.effects[1].id = tes3.effect.mistyStep
        spell.effects[1].rangeType = tes3.effectRange.self
    end
    ---@cast spell tes3spell
    local enchantment = tes3.getObject(constants.ENCHANTMENT_ID)
    if not enchantment then
        enchantment = tes3.createObject({
            id = constants.ENCHANTMENT_ID,
            objectType = tes3.objectType.enchantment,
            castType = tes3.enchantmentType.castOnce,
            chargeCost = constants.MAGICKA_COST,
            maxCharge = constants.MAGICKA_COST
        })
        enchantment.effects[1].id = tes3.effect.mistyStep
        enchantment.effects[1].rangeType = tes3.effectRange.self
        tes3.setSourceless(enchantment)
    end
    ---@cast enchantment tes3enchantment
    local scroll = tes3.getObject(constants.SCROLL_ID)
    if not scroll then
        scroll = tes3.createObject({
            id = constants.SCROLL_ID,
            objectType = tes3.objectType.book
        })
        tes3.setSourceless(scroll)
        scroll.name = "Scroll of Misty Step"
        scroll.value = 112
        scroll.weight = 0.2
        scroll.icon = "m\\tx_scroll_01.tga"
        scroll.mesh = "m\\text_scroll_01.nif"
        scroll.type = tes3.bookType.scroll
        scroll.enchantment = enchantment
    end
    ---@cast scroll tes3book

    local scrollLeveledList = tes3.getObject("random_scroll_all")
    if scrollLeveledList and scrollLeveledList.objectType ==
        tes3.objectType.leveledItem then
        ---@cast scrollLeveledList tes3leveledItem
        scrollLeveledList:insert(scroll, 1)
        log:debug(
            "Inserted Misty Step scroll into random_scroll_all leveled list")
    else
        log:error(
            "Could not find random_scroll_all leveled list to insert Misty Step scroll")
    end

    for npc in tes3.iterateObjects(tes3.objectType.npc) do
        ---@cast npc tes3npc
        if npc.aiConfig.offersSpells then
            if tes3.hasSpell({actor = npc, spell = "mark"}) or
                tes3.hasSpell({actor = npc, spell = "recall"}) or
                tes3.hasSpell({actor = npc, spell = "telekinesis"}) then
                local wasAdded = tes3.addSpell({
                    actor = npc,
                    spell = spell,
                    updateGUI = false
                })
                if wasAdded then
                    log:debug("Added Misty Step spell to %s", npc.id)
                end
            end
        end

        if npc.inventory:contains("sc_mark") or
            npc.inventory:contains("sc_leaguestep") or
            npc.inventory:contains("sc_inasismysticfinger") then
            if npc.aiConfig.bartersBooks then
                npc.inventory:addItem({item = scroll, count = -1})
                if npc.inventory:contains(scroll) then
                    log:debug("Added Misty Step scroll to %s's inventory",
                              npc.id)
                end
            end
        end
    end
    log:info("Misty Step initialized.")
end)

-- Cache failed validations between `spellMagickaUse` and `spellCast` events.
local pendingFailedCasts = {}

-- Pre-validate landing during spellMagickaUse and prevent magicka spending on failure.
event.register(tes3.event.spellMagickaUse, function(e)
    if not e.spell or e.spell.id ~= constants.SPELL_ID then return end
    log:debug("spellMagickaUse event for Misty Step detected.")

    local casterRef = e.caster
    if not casterRef then
        log:debug("spellMagickaUse: missing caster reference")
        return
    end

    local mobile = casterRef.mobile
    if not mobile then
        log:debug("spellMagickaUse: caster has no mobile component")
        return
    end
    ---@cast mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer

    local magickaCost = e.cost or 0
    if mobile.magicka and mobile.magicka.current and mobile.magicka.current <
        magickaCost then
        log:debug(
            "spellMagickaUse: insufficient magicka (have=%.0f need=%.0f), skipping landing validation",
            mobile.magicka.current, magickaCost)
        return
    end

    local ray = blink.getBlinkRay(mobile)
    local landing = blink.findLandingPosition(casterRef, ray)
    if not landing then
        log:info(
            "spellMagickaUse: no valid landing, preventing magicka cost for %s",
            casterRef.id or "unknown")
        e.cost = 0
        pendingFailedCasts[casterRef] = "no-landing"
    end
end)

-- Cancel the cast in spellCast if pre-validation failed, and show player-facing message.
event.register(tes3.event.spellCast, function(e)
    if not e.source or e.source.id ~= constants.SPELL_ID then return end
    log:debug("spellCast event for Misty Step detected.")

    local casterRef = e.caster
    if not casterRef then return end

    log:debug("spellCast: source=%s castChance=%.2f",
              e.source and (e.source.id or "unknown") or "nil",
              e.castChance or 0)
    local reason = pendingFailedCasts[casterRef]
    if reason then
        pendingFailedCasts[casterRef] = nil
        log:info("spellCast: cancelling Misty Step cast for %s due to %s",
                 casterRef.id or "unknown", tostring(reason))
        if casterRef == tes3.player then
            tes3.messageBox("Misty Step failed: no safe landing spot found.")
        end
        e.castChance = 0
    else
        if (e.castChance or 0) == 0 then
            log:warn(
                "spellCast: castChance is 0 for %s but no pre-validation flag set; cast failed for another reason",
                casterRef.id or "unknown")
        end
    end
end)

require("MistyStep.mcm")
