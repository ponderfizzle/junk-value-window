local frame
local titleText
local totalText
local statusText
local pendingItems = {}

local function getContainerItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then
            return info.itemID, info.stackCount
        end
        return nil, nil
    end

    if GetContainerItemInfo then
        local _, count = GetContainerItemInfo(bag, slot)
        local itemID = GetContainerItemID and GetContainerItemID(bag, slot)
        return itemID, count
    end

    return nil, nil
end

local function getBagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    end

    if GetContainerNumSlots then
        return GetContainerNumSlots(bag)
    end

    return 0
end

local function requestItemData(itemID)
    if itemID and not pendingItems[itemID] and C_Item and C_Item.RequestLoadItemDataByID then
        pendingItems[itemID] = true
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

local function getItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(itemID)
    end

    if GetItemInfo then
        return GetItemInfo(itemID)
    end

    return nil
end

local function formatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local remainder = copper % 100
    local parts = {}

    if gold > 0 then
        parts[#parts + 1] = gold .. "g"
    end
    if silver > 0 then
        parts[#parts + 1] = silver .. "s"
    end
    if remainder > 0 or #parts == 0 then
        parts[#parts + 1] = remainder .. "c"
    end

    return table.concat(parts, " ")
end

local function resizeWindow()
    if not frame or not titleText or not totalText then
        return
    end

    local width = math.max(titleText:GetStringWidth(), totalText:GetStringWidth())
    local height = titleText:GetStringHeight() + totalText:GetStringHeight() + 19

    if statusText:IsShown() then
        width = math.max(width, statusText:GetStringWidth())
        height = height + statusText:GetStringHeight() + 3
    end

    frame:SetSize(width + 16, height)
end

local function updateValue()
    if not totalText then
        return
    end

    local total = 0
    local waitingForData = false
    local bagCount = NUM_BAG_SLOTS or 4

    for bag = 0, bagCount do
        for slot = 1, getBagSlots(bag) do
            local itemID, count = getContainerItemInfo(bag, slot)
            if itemID then
                local name, _, quality, _, _, _, _, _, _, _, sellPrice = getItemInfo(itemID)

                if not name then
                    waitingForData = true
                    requestItemData(itemID)
                elseif quality == 0 then
                    total = total + (sellPrice or 0) * (count or 1)
                end
            end
        end
    end

    totalText:SetText(formatMoney(total))
    if waitingForData then
        statusText:SetText("Loading item data...")
        statusText:Show()
    else
        statusText:Hide()
    end
    resizeWindow()
end

local function savePosition()
    if not JunkValueDB then
        JunkValueDB = {}
    end

    local point, _, relativePoint, x, y = frame:GetPoint()
    JunkValueDB.point = point
    JunkValueDB.relativePoint = relativePoint
    JunkValueDB.x = x
    JunkValueDB.y = y
end

local function createWindow()
    frame = CreateFrame("Frame", "JunkValueFrame", UIParent)
    frame:SetSize(100, 50)
    frame:SetFrameStrata("HIGH")
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition()
    end)
    frame:SetPoint(
        JunkValueDB and JunkValueDB.point or "CENTER",
        UIParent,
        JunkValueDB and JunkValueDB.relativePoint or "CENTER",
        JunkValueDB and JunkValueDB.x or 0,
        JunkValueDB and JunkValueDB.y or 0
    )

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
    background:SetVertexColor(0.05, 0.05, 0.05, 0.85)

    titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -7)
    titleText:SetText("Junk Value")

    totalText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    totalText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -5)
    totalText:SetText("0c")

    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    statusText:SetPoint("TOPLEFT", totalText, "BOTTOMLEFT", 0, -3)
    statusText:SetText("Loading item data...")
    statusText:Hide()

    resizeWindow()
    frame:Show()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
eventFrame:SetScript("OnEvent", function(_, event, itemID)
    if event == "PLAYER_LOGIN" then
        createWindow()
        updateValue()
    elseif event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        if itemID then
            pendingItems[itemID] = nil
        end
        updateValue()
    else
        updateValue()
    end
end)

SLASH_JUNKVALUE1 = "/junkvalue"
SlashCmdList.JUNKVALUE = function()
    if not frame then
        return
    end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        updateValue()
    end
end
