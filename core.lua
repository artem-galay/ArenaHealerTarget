local f=CreateFrame("Frame")
f:RegisterEvent("START_TIMER")

local function detectArenaHealer()
	print("AHT info started")
	
	local specID1, _ = GetArenaOpponentSpec(1)
	if specID1 == nil then
		_G["ahtTimerInProgress"] = false
		print("AHT info finished (not enough enemy players info)")	
		return 
	end
	local _, name1, _, _, role1, _, _ = GetSpecializationInfoByID(specID1)
	
	local specID2, _ = GetArenaOpponentSpec(2)
	if specID2 == nil then
		_G["ahtTimerInProgress"] = false
		print("AHT info finished (not enough enemy players info)")	
		return 
	end
	local _, name2, _, _, role2, _, _ = GetSpecializationInfoByID(specID2)
	
	local specID3, _ = GetArenaOpponentSpec(3)
	local name3, role3
	if specID3 ~= nil then 
		_, name3, _, _, role3, _, _ = GetSpecializationInfoByID(specID3) 
	end
	
	local healerRole = "HEALER"
	local healerTargetLocal = "focus"
	local mainTarget = "arena1"
	local focusTarget = "arena2"
	if role1 == healerRole then 
		healerTargetLocal = "arena1"
		mainTarget = "arena2"
		focusTarget = "arena3"
	elseif role2 == healerRole then 
		healerTargetLocal = "arena2"
		mainTarget = "arena1"
		focusTarget = "arena3"			
	elseif role3 == healerRole then 
		healerTargetLocal = "arena3"
		mainTarget = "arena1"
		focusTarget = "arena2"	
	end
	
	if role3 == nil then
		mainTarget = "arena1"
		focusTarget = "arena2"
	end
	
	print("healerTarget =", healerTargetLocal)
	print("mainTarget =", mainTarget, "focusTarget =", focusTarget)

	EditAhtMacro(healerTargetLocal, mainTarget, focusTarget, "focus")

	_G["ahtTimerInProgress"] = false
	print("AHT info finished")
end

local function detectBattlegroundHealers()
	RequestBattlefieldScoreData()
	C_Timer.After(1, function() 
		print("AHT(BG) info started")

		local numBattlefieldScores = GetNumBattlefieldScores()
		print("numBattlefieldScores =", numBattlefieldScores)
		
		local name, realm = UnitFullName("player")
		print("playerName & realm = "..name.."-"..realm)
		local playerFullName = name.."-"..realm
		local playerFaction = 0
		
		for i = 1, numBattlefieldScores, 1 do
			local info = C_PvP.GetScoreInfo(i)
			if info.name == playerFullName then
				playerFaction = info.faction
				print("playerFaction = "..playerFaction)
				break
			end
		end
		
		local healer1 = "focus"
		local healer2 = "focus"
		local healersCount = 0
		for i = 1, numBattlefieldScores, 1 do
			local info = C_PvP.GetScoreInfo(i)
			if info.faction ~= playerFaction and info.roleAssigned == 4 then
				healersCount = healersCount + 1
				if healersCount == 1 then
					healer1 = info.name
				else
					healer2 = info.name
				end
				print(i, info.name, "faction = ", info.faction, info.talentSpec, "roleAssigned = ", info.roleAssigned)
				if healersCount == 2 then break end
			end
		end
		
		if healersCount == 0 then
			print("healersCount =", healersCount)
		else
			print("healer1 =", healer1)
			print("healer2 =", healer2)
			
			local healer1Name, healer1Realm = healer1:match("([^-]+)-([^-]+)")
			local healer2Name, healer2Realm = healer2:match("([^-]+)-([^-]+)")
			
			WeakAurasSaved["healer1FullNameG"] = healer1
			WeakAurasSaved["healer2FullNameG"] = healer2
			EditAhtMacro(healer1, "target", "focus", healer2)
		end
		
		_G["ahtTimerInProgress"] = false
		print("AHT(BG) info finished")
		--[[
		if healersCount > 0 then
			print("You should reload UI")
			local b = CreateFrame("BUTTON", nil, UIParent, "SecureHandlerClickTemplate");
			b:SetSize(50,50)
			b:SetPoint("CENTER",0,0)
			b:RegisterForClicks("AnyUp")
			b:SetNormalTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Up")
			b:SetPushedTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
			b:SetHighlightTexture("Interface\\Vehicles\\UI-Vehicles-Button-Exit-Down")
			b:SetScript("OnClick", function(self) ReloadUI() end)
			
			local text = UIParent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			text:SetPoint("CENTER", 0, 50)
			text:SetText("You should reload UI")
			C_Timer.After(15, function() text:Hide() end)
		end
		]]--
	end)
end

function EditAhtMacro(healerTargetLocal, firstDpsTarget, secondDpsTarget, focusTarget)
	print("editAhtMacro started")
	-- Start at the end, and move backward to first position (121).
	for i = 120 + select(2,GetNumMacros()), 121, -1 do
		local name, icon, body = GetMacroInfo(i)
		if string.sub(name, 1, 4) == "!AHT" then
			local bodyWithHealerTargetReplaced, _ = string.gsub(body, "(!ht)", healerTargetLocal)
			local bodyWithFirstDpsTargetReplaced, _ = string.gsub(bodyWithHealerTargetReplaced, "(!1dd)", firstDpsTarget)
			local bodyWithSecondDpsTargetReplaced, _ = string.gsub(bodyWithFirstDpsTargetReplaced, "(!2dd)", secondDpsTarget)
			local bodyWithFocusTargetReplaced, _ = string.gsub(bodyWithSecondDpsTargetReplaced, "(!ft)", focusTarget)
			local bodyWithAnchorsReplaced = bodyWithFocusTargetReplaced
			local nameWithoutPrefix, _ = string.sub(name, 5)
			local existedName, existedIcon, _ = GetMacroInfo(nameWithoutPrefix)
			if existedName == nil then
				CreateMacro(nameWithoutPrefix, icon, bodyWithAnchorsReplaced, nil)
			else
				EditMacro(existedName, nil, nil, bodyWithAnchorsReplaced)
			end
		end
	end
end

local function OnEvent(self, event, arg1, arg2, arg3, ...)
	if arg2 < 11 then
		print("AHT will not start, timer is less than 11 sec")
		return
	end
	
	if _G["ahtTimerInProgress"] == true then
		return
	end
	
	_G["ahtTimerInProgress"] = true

	local isArena, isRegistered = IsActiveBattlefieldArena()
	
	local delayInSeconds = arg2-10
    print("AHT info event handled, will start after "..delayInSeconds.." sec")
	if isArena then
		C_Timer.After(delayInSeconds, detectArenaHealer)
	else
		C_Timer.After(delayInSeconds, detectBattlegroundHealers)
	end	
end 

f:SetScript("OnEvent", OnEvent)

SLASH_AHT1 = '/aht'
SLASH_AHTBG1 = '/ahtbg'
SLASH_AHTHELP1 = '/ahthelp'

function SlashCmdList.AHT(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
    detectArenaHealer()
end

function SlashCmdList.AHTBG(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
    detectBattlegroundHealers()
end

function SlashCmdList.AHTHELP(msg, editBox)
	print("/aht - run Arena module manually")
	print("/ahtbg - run BG module manually")
	print("/ahthelp - help")
	print("This addon will detect enemies' healers and replace special marks in your macro with healers' arena units (when in Arena) or with healers' nicknames (when in BG).")
	print("Addon automatically starts when you entered Arena or BG (handling START_TIMER event). It will modify your macro 10 second before gates open.")
	print("To make it works create character-specific (in second macro tab) macro with special '!AHT*' prefix in its name (!AHTFear for examle).")
	print("Addon will create new macro without '!AHT*' prefix in its name (!AHTFear -> Fear) or modify existed macro with that name.")
	print("List of special marks for macro:")
	print("!ht - will be replaced with healer arena unit (for Arena match) or with 1st enemy healer's nickname (for BGs)")
	print("!1dd - will be replaced with 1st dps arena unit (for Arena match, unused in BGs)")
	print("!2dd - will be replaced with 2nd dps arena unit (for Arena match, unused in BGs)")
	print("!ft - will be replaced with constant 'focus' unit (for Arena match) or with 2nd enemy healer's nickname (for BGs)")
	print("======================")
	print("Macro example:")
	print("/tar [mod:shift] !ht; [mod:ctrl] !ft")
	print("/cast Fear")
	print("/targetlasttarget [mod:shift][mod:ctrl]")
	print("======================")
	print("After marks replacing when in ARENA will look like:")
	print("/tar [mod:shift] arena2; [mod:ctrl] focus")
	print("/cast Fear")
	print("/targetlasttarget [mod:shift][mod:ctrl]")
	print("Cast Fear to healer with SHIFT, to focus with CTRL, or to target without modifier.")
	print("======================")
	print("After marks replacing when in BG will look like:")
	print("/tar [mod:shift] Besthealereu-Doomahmmer; [mod:ctrl] Worsthealereu-Turalyon")
	print("/cast Fear")
	print("/targetlasttarget [mod:shift][mod:ctrl]")
	print("Cast Fear to healer1 with SHIFT, to healer2 with CTRL, or to target without modifier.")
end