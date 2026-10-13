-- Kontor: mailbox button on characters without enchanting (Nachtrag 2, 5; M13).
-- Fills the send-mail form with disenchant goods for the bank character.
-- Sending stays with the user.

local _, Kontor = ...

local MAX_ATTACH = ATTACHMENTS_MAX_SEND or 12
local button

function Kontor:BankCharName()
    local cfg = self.db.config
    return cfg.bankCharName or cfg.enchanterName
end

-- Unbound bag items whose best use is disenchanting on the bank character.
function Kontor:FindMailGoods()
    local list = {}
    self:ForEachBagItem(function(bag, slot, info)
        if info.isBound or self:FindBasketItem(info.itemID) or self.db.deExclusions[info.itemID] then return end
        local a = self:DisenchantAdvice(info.hyperlink or info.itemID, false)
        if a and a.advice == "an Bankchar schicken" then
            table.insert(list, { bag = bag, slot = slot, itemID = info.itemID, link = info.hyperlink })
        end
    end)
    return list
end

local function update()
    if not button then return end
    local name = Kontor:BankCharName()
    if Kontor:IsEnchanter() then
        button:Hide()
        return
    end
    button:Show()
    if not name then
        button:SetText("Kontor: Bankchar unbekannt (Einstellungen)")
        button:Disable()
        return
    end
    local goods = Kontor:FindMailGoods()
    button:SetText("Kontor: Entzauberware an " .. name .. " (" .. #goods .. " Items)")
    button:SetEnabled(#goods > 0)
end

local function fillMail()
    local name = Kontor:BankCharName()
    local goods = Kontor:FindMailGoods()
    if not name or #goods == 0 then return end
    if MailFrameTab_OnClick then MailFrameTab_OnClick(nil, 2) end
    if SendMailNameEditBox then SendMailNameEditBox:SetText(name) end
    local attached = 0
    for _, g in ipairs(goods) do
        if attached >= MAX_ATTACH then break end
        C_Container.PickupContainerItem(g.bag, g.slot)
        local ok = pcall(ClickSendMailItemButton)
        if not ok or CursorHasItem() then
            ClearCursor()
            Kontor:Print("Anhängen per Addon nicht möglich. Bitte von Hand anhängen:")
            for _, rest in ipairs(goods) do DEFAULT_CHAT_FRAME:AddMessage("  " .. (rest.link or Kontor:ItemLabel(rest.itemID))) end
            return
        end
        attached = attached + 1
    end
    Kontor:Print(attached .. " Items an " .. name .. " angehängt. Abschicken bitte selbst."
        .. (#goods > attached and (" Weitere " .. (#goods - attached) .. " passen in den nächsten Brief.") or ""))
end

Kontor:RegisterEvent("MAIL_SHOW", "Briefkasten", function()
    if not button and MailFrame then
        button = Kontor:CreateButton(MailFrame, "", 330, fillMail)
        button:SetPoint("BOTTOMLEFT", MailFrame, "TOPLEFT", 60, 2)
    end
    update()
end)
Kontor:RegisterEvent("MAIL_CLOSED", "Briefkasten", function() if button then button:Hide() end end)
Kontor:RegisterEvent("BAG_UPDATE_DELAYED", "Briefkasten", function()
    if button and button:IsShown() then update() end
end)
