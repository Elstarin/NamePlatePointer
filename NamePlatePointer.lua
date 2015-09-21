local NamePlatePointer = {}
local NPP = NamePlatePointer
NPP.plates = {}
local PlateWidth, PlateHeight = 40, 40 -- Set to desired width and height, defaults are about 141x39
local SizePlates
local PlateSizer = CreateFrame("Frame", nil, WorldFrame, "SecureHandlerStateTemplate")

local function reaction(plate)
  local red, green, blue = plate.ArtContainer.HealthBar:GetStatusBarColor()

  if red < 0.01 then
    if blue < 0.01 and green > 0.99 then
      return false, "NPC" -- Friendly NPC
    elseif blue > 0.99 and green < 0.01 then
      return false, "PLAYER" -- Friendly player
    end
  elseif red > 0.99 then
    if blue < 0.01 and green > 0.99 then
      return true, "NPC" -- Neutral NPC
    elseif blue < 0.01 and green < 0.01 then
      return true, "NPC" -- Hostile NPC
    end
  elseif red > 0.5 and red < 0.6 then
    if green > 0.5 and green < 0.6 and blue > 0.5 and blue < 0.6 then
      return false, "NPC" -- Tapped NPC (I think that means dead?)
    end
  end

  return true, "PLAYER" -- Hostile player
end

local function plateClick(plate)
  local leftDown = IsMouseButtonDown("LeftButton")
  local rightDown = IsMouseButtonDown("RightButton")

  if leftDown then
    print("Left click", IsMouselooking())
    MouselookStart()
    NPP.mouselooking = true
  elseif rightDown then
    print("Right click", IsMouselooking())
    MouselookStart()
  end
end

local function hidePlate(plate)
  plate.ArtContainer:Hide()
  plate.NameContainer:Hide()
  -- plate.NameContainer.NameText:Hide()
  --
  -- plate.ArtContainer.Highlight:SetTexture()
  -- plate.ArtContainer.AggroWarningTexture:SetTexture()
  -- plate.ArtContainer.HighLevelIcon:SetTexture()

  -- plate.ArtContainer.RaidTargetIcon:SetAlpha(0)
  -- plate.ArtContainer.EliteIcon:SetAlpha(0)
  --
  -- plate.ArtContainer.CastBarBorder:Hide()
  -- plate.ArtContainer.LevelText:SetWidth(0.001)
  -- plate.ArtContainer.LevelText:Hide()
  -- plate.ArtContainer.HealthBar:Hide()
  -- plate.ArtContainer.Border:Hide()
  --
  -- plate.ArtContainer.CastBarText:Hide()
  -- plate.ArtContainer.CastBarFrameShield:Hide()
  -- plate.ArtContainer.AbsorbBar:Hide()
  -- plate.ArtContainer.CastBarTextBG:SetTexture()
  -- plate.ArtContainer.CastBarSpellIcon:SetTexCoord(0, 0, 0, 0)
end

local function plateShow(plate)
  -- if not reaction(plate) then
  --   print("Showing plate:", plate.NameContainer.NameText:GetText(), reaction(plate))
  --   plate:SetScript("OnMouseDown", plateClick)
  --   -- hidePlate(plate)
  -- end
end

local function plateHide(plate)
  -- if reaction(plate.ArtContainer.HealthBar:GetStatusBarColor()) then
    -- plate.ArtContainer:Show()
    -- plate.NameContainer:Show()
  -- end

  plate:SetScript("OnMouseDown", nil)
  -- plate.ArtContainer:Show()
  -- plate.NameContainer:Show()
end

local plateIndex
local index = 2
local function updateHandler(self, elapsed)
  if plateIndex then
    while _G["NamePlate" .. plateIndex] do

      local plate = _G["NamePlate" .. plateIndex]

      NPP.plates[#NPP.plates + 1] = plate

      NPP.anchor = plate

      -- NPP.line:ClearAllPoints()
      -- NPP.line:SetPoint("TOP", NPP.anchor)
      -- NPP.line:SetPoint("BOTTOM", NPP.main)

      local text = plate.NameContainer.NameText:GetText()

      -- print("Registering NamePlate" .. plateIndex .. ".", plate.NameContainer.NameText:GetText(), reaction(plate))

      if not reaction(plate) then
        plate:HookScript("OnShow", plateShow)
        -- plate:HookScript("OnHide", plateHide)
        plate:SetScript("OnMouseDown", plateClick)

        plate:GetChildren():SetSize(PlateWidth, PlateHeight)
        PlateSizer:WrapScript(plate, "OnShow", SizePlates)
        plate:SetAttribute("WrappedForSizing", true)
        plate:SetAttribute("Friendly", true)

        -- hidePlate(plate)
        print("Scaling", text .. ".")
      else
        print("Not scaling", text .. ".")
      end

      plateIndex = plateIndex + 1
    end
  else -- Search for the starting nameplate index number
    local numChildren = WorldFrame:GetNumChildren()

    if numChildren >= index then
      for i = index, numChildren do
        local child = select(i, WorldFrame:GetChildren())
        if child and child.ArtContainer and child.ArtContainer.HealthBar then -- If it has these, that should guarantee it's a nameplate
          plateIndex = child:GetName():match("^NamePlate(%d+)") + 0
          break
        else -- This one isn't a nameplate, so skip it next time for a tiny bit of efficiency
          index = i + 1
        end
      end
    end
  end

  if NPP.mouselooking then
    if not IsMouseButtonDown("LeftButton") then
      MouselookStop()

      NPP.mouselooking = false
    end
  end

  if NPP.anchor then
    -- print("Setting anchor", GetTime())
    -- NPP.line:ClearAllPoints()
    -- NPP.line:SetPoint("TOP", NPP.anchor)
    -- NPP.line:SetPoint("BOTTOM", NPP.main)
  end
end

NPP.main = CreateFrame("Frame", "NPP_Main_Anchor")
NPP.main:SetScript("OnUpdate", updateHandler)
NPP.main:SetPoint("CENTER")
NPP.main:SetSize(20, 20)

NPP.line = NPP.main:CreateTexture("NPP_Line", "OVERLAY")
NPP.line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
NPP.line:SetSize(5, 200)

do -- Scaling stuff
  --[[ Semlar's Magical Plate Resizer! ]]--
  PlateSizer:Execute("Children, TempFrames, WorldFrame = newtable(), newtable(), self:GetParent()")

  SizePlates = format([[
  if newstate ~= "off" then
    print("Sizing Plates")
    wipe(Children)
    for i = 1, #WorldFrame:GetChildList(Children) do
      local f = Children[i]
      local name = f:GetName()

      if name and strmatch(name, "^NamePlate%%d+$") then
        local clicky = f:GetChildren()

        if not f:GetAttribute("Friendly") then
          clicky:SetWidth(%d)
          clicky:SetHeight(%d)
        else
          clicky:SetWidth(141)
          clicky:SetHeight(39)
        end

        if not f:GetAttribute("WrappedForSizing") then
          local temp = tremove(TempFrames, 1)
          temp:SetParent(f)
          tinsert(TempFrames, temp)
          f:SetAttribute("WrappedForSizing", true)
        end
      end
    end
  end
  ]], PlateWidth, PlateHeight)

  local TempFrames = {}
  for i = 1, 50 do
    local f = CreateFrame("Frame", nil, nil, "SecureHandlerShowHideTemplate")
    PlateSizer:WrapScript(f, "OnShow", SizePlates)
    PlateSizer:SetFrameRef("temp", f)
    PlateSizer:Execute("tinsert(TempFrames, self:GetFrameRef(\"temp\"))")
    tinsert(TempFrames, f)
  end

  -- PlateSizer:SetAttribute("_onstate-mousestate", SizePlates)
  -- RegisterStateDriver(PlateSizer, "mousestate", "[@mouseover,exists,combat] on; off")

  -- PlateSizer:SetScript("OnEvent", function(self, event)
  --   if event == "PLAYER_REGEN_ENABLED" then
  --     for i = 1, #TempFrames do
  --       TempFrames[i]:SetParent(nil)
  --     end
  --
  --     self:Show()
  --     SecureStateDriverManager:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
  --   else
  --     self:Hide()
  --     SecureStateDriverManager:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  --   end
  -- end)
  --
  -- PlateSizer:RegisterEvent("PLAYER_REGEN_ENABLED")
  -- PlateSizer:RegisterEvent("PLAYER_REGEN_DISABLED")
end

-- local Wrapped = {}
-- local PrevWorldChildren = 0
-- local function IterateChildren(f, ...)
--   if not f then return end
--
--   local name = f:GetName()
--
--   if not Wrapped[f] and name and strmatch(name, "^NamePlate%d+$") then
--     Wrapped[f] = true
--     f:GetChildren():SetSize(PlateWidth, PlateHeight)
--     PlateSizer:WrapScript(f, "OnShow", SizePlates)
--     f:SetAttribute("WrappedForSizing", true)
--   end
--
--   IterateChildren(...)
-- end
--
-- PlateSizer:SetScript("OnUpdate", function()
--   local numChildren = WorldFrame:GetNumChildren()
--
--   if numChildren ~= PrevWorldChildren then PrevWorldChildren = numChildren
--     IterateChildren(WorldFrame:GetChildren())
--   end
-- end)
