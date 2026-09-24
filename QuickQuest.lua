local ADDON_NAME = ...

local QuickQuest = CreateFrame("Frame")
QuickQuest.enabled = true

-- Hold Shift to skip automation for a single interaction
local function IsBypassed()
    return IsShiftKeyDown()
end

local function ShouldAct()
    return QuickQuest.enabled and not IsBypassed()
end

-- ===== Quest accept / turn-in =====

local function AutoAcceptQuest()
    if not ShouldAct() then return end
    AcceptQuest()
end

local function AutoCompleteQuest()
    if not ShouldAct() then return end
    if IsQuestCompletable() then
        CompleteQuest()
    end
end

local function AutoChooseReward()
    if not ShouldAct() then return end
    local numChoices = GetNumQuestChoices()
    -- Only auto-confirm when there's nothing to actually choose between.
    -- Multiple reward choices are left for you to pick by hand.
    if numChoices == 0 then
        GetQuestReward(1)
    elseif numChoices == 1 then
        GetQuestReward(1)
    end
end

-- ===== NPC greeting screen (multiple quests on one NPC, old-style) =====

local function AutoHandleGreeting()
    if not ShouldAct() then return end
    local numActive = GetNumActiveQuests() or 0
    local numAvailable = GetNumAvailableQuests() or 0

    if numActive == 1 and numAvailable == 0 then
        SelectActiveQuest(1)
    elseif numAvailable == 1 and numActive == 0 then
        SelectAvailableQuest(1)
    end
    -- If the NPC offers more than one quest, we leave the greeting
    -- window open so you can pick which one.
end

-- ===== Modern gossip frame =====

local function AutoHandleGossip()
    if not ShouldAct() then return end

    local activeQuests = C_GossipInfo.GetActiveQuests()
    local availableQuests = C_GossipInfo.GetAvailableQuests()
    local options = C_GossipInfo.GetOptions()

    local numActive = activeQuests and #activeQuests or 0
    local numAvailable = availableQuests and #availableQuests or 0
    local numOptions = options and #options or 0

    if numActive == 1 and numAvailable == 0 then
        C_GossipInfo.SelectActiveQuest(activeQuests[1].questID)
    elseif numAvailable == 1 and numActive == 0 then
        C_GossipInfo.SelectAvailableQuest(availableQuests[1].questID)
    elseif numActive == 0 and numAvailable == 0 and numOptions == 1 then
        -- e.g. a single "I'm looking for work" style gossip option
        C_GossipInfo.SelectOption(options[1].gossipOptionID)
    end
end

-- ===== Event wiring =====

QuickQuest:RegisterEvent("ADDON_LOADED")
QuickQuest:RegisterEvent("QUEST_DETAIL")
QuickQuest:RegisterEvent("QUEST_PROGRESS")
QuickQuest:RegisterEvent("QUEST_COMPLETE")
QuickQuest:RegisterEvent("QUEST_GREETING")
QuickQuest:RegisterEvent("GOSSIP_SHOW")

QuickQuest:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            QuickQuestDB = QuickQuestDB or { enabled = true }
            QuickQuest.enabled = QuickQuestDB.enabled
            print("|cff33ff99QuickQuest|r loaded. /qq to toggle, hold Shift to bypass.")
        end
    elseif event == "QUEST_DETAIL" then
        AutoAcceptQuest()
    elseif event == "QUEST_PROGRESS" then
        AutoCompleteQuest()
    elseif event == "QUEST_COMPLETE" then
        AutoChooseReward()
    elseif event == "QUEST_GREETING" then
        AutoHandleGreeting()
    elseif event == "GOSSIP_SHOW" then
        AutoHandleGossip()
    end
end)

-- ===== Slash command =====

SLASH_QUICKQUEST1 = "/qq"
SlashCmdList["QUICKQUEST"] = function()
    QuickQuest.enabled = not QuickQuest.enabled
    QuickQuestDB.enabled = QuickQuest.enabled
    print("|cff33ff99QuickQuest|r " .. (QuickQuest.enabled and "enabled" or "disabled"))
end
