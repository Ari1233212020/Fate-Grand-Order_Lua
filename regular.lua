--[[
このスクリプトは人の動きを真似してるだけなので、サーバーには余計な負担を掛からないはず。
私の国では仕事時間は異常に長いので、もう満足プレイする時間すらできない。休日を使ってシナリオを読むことがもう精一杯…
お願いします。このプログラムを禁止しないでください。
]]

--Main loop, pattern detection regions.
--Click pos are hard-coded into code, unlikely to change in the future.
MenuRegion = Region(2100,1200,1000,1000)
BattleRegion = Region(2200,200,1000,600)
ResultRegion = Region(100,300,700,200)
QuestrewardRegion = Region(1630,140,370,250)
StaminaRegion = Region(600,200,300,300)

StoneClick = (Location(1270,340))
AppleClick = (Location(1270,640))

--Weak, resist, etc. Compatiable for most server, but tricky, frequently fail.
Card1AffinRegion = Region( 295,650,250,200)
Card2AffinRegion = Region( 810,650,250,200)
Card3AffinRegion = Region(1321,650,250,200)
Card4AffinRegion = Region(1834,650,250,200)
Card5AffinRegion = Region(2348,650,250,200)

CardAffinRegionArray = {Card1AffinRegion, Card2AffinRegion, Card3AffinRegion, Card4AffinRegion, Card5AffinRegion}

--Buster, Art, Quick, etc.
Card1TypeRegion = Region(200,1060,200,200)
Card2TypeRegion = Region(730,1060,200,200)
Card3TypeRegion = Region(1240,1060,200,200)
Card4TypeRegion = Region(1750,1060,200,200)
Card5TypeRegion = Region(2280,1060,200,200)

CardTypeRegionArray = {Card1TypeRegion, Card2TypeRegion, Card3TypeRegion, Card4TypeRegion, Card5TypeRegion}

--*Rough* damage calculation by formula, you may tinker these to change card selection priority.
--https://pbs.twimg.com/media/C2nSYxcUoAAy_F2.jpg
WeakMulti = 2.0
NormalMulti = 1.0
ResistMulti = 0.5

BCard = 150
ACard = 100
QCard = 80

ResistBuster =  BCard * ResistMulti
ResistArt = ACard * ResistMulti
ResistQuick = QCard * ResistMulti

WeakBuster = BCard * WeakMulti
WeakArt = ACard * WeakMulti
WeakQuick = QCard * WeakMulti

--User customizable BAQ selection priority.
CardPriorityArray = {}

--Card selection pos for click, and array for AutoSkill.
Card1Click = (Location(300,1000))
Card2Click = (Location(750,1000))
Card3Click = (Location(1300,1000))
Card4Click = (Location(1800,1000))
Card5Click = (Location(2350,1000))

CardClickArray = {Card1Click, Card2Click, Card3Click, Card4Click, Card5Click}

--*Primitive* ways to spam NPs after priority target appeared in battle. IT WILL override autoskill NP skill. Check function ultcard()
Ultcard1Click = (Location(1000,220))
Ultcard2Click = (Location(1300,400))
Ultcard3Click = (Location(1740,400))

--Priority target detection region and selection region.
Target1Type = Region(0,0,485,220)
Target2Type = Region(485,0,482,220)
Target3Type = Region(967,0,476,220)
Target1Choose = (Location(90,80))
Target2Choose = (Location(570,80))
Target3Choose = (Location(1050,80))

--NpbarRegion = Region(280,1330,1620,50)
--Ultcard1Region = Region(900,100,200,200)
--Ultcard2Region = Region(1350,100,200,200)
--Ultcard3Region = Region(1800,100,200,200)

--Autoskill click regions.
Skill1Click = (Location(140,1160))
Skill2Click = (Location(340,1160))
Skill3Click = (Location(540,1160))

Skill4Click = (Location(770,1160))
Skill5Click = (Location(970,1160))
Skill6Click = (Location(1140,1160))

Skill7Click = (Location(1400,1160))
Skill8Click = (Location(1600,1160))
Skill9Click = (Location(1800,1160))

Master1Click = (Location(1820,620))
Master2Click = (Location(2000,620))
Master3Click = (Location(2160,620))

Servant1Click = (Location(700,880))
Servant2Click = (Location(1280,880))
Servant3Click = (Location(1940,880))

--Autoskill related variables, check function decodeSkill(str, isFirstSkill).
SkillClickArray = {Skill1Click, Skill2Click, Skill3Click, Skill4Click, Skill5Click, Skill6Click, Skill7Click, Skill8Click, Skill9Click, Master1Click, Master2Click, Master3Click}
SkillClickArray[-47] = Servant1Click
SkillClickArray[-46] = Servant2Click
SkillClickArray[-45] = Servant3Click
SkillClickArray[-44] = Ultcard1Click
SkillClickArray[-43] = Ultcard2Click
SkillClickArray[-42] = Ultcard3Click

stageSkillArray = {}
stageSkillArray[1] = {}
stageSkillArray[2] = {}
stageSkillArray[3] = {}
stageSkillArray[4] = {}
stageSkillArray[5] = {}

startingMember1Click = (Location(280,700))
startingMember2Click = (Location(680,700))
startingMember3Click = (Location(1080,700))
startingMemberClickArray = {}
startingMemberClickArray[-47] = startingMember1Click
startingMemberClickArray[-46] = startingMember2Click
startingMemberClickArray[-45] = startingMember3Click

subMember1Click = (Location(1480,700))
subMember2Click = (Location(1880,700))
subMember3Click = (Location(2280,700))
subMemberClickArray = {}
subMemberClickArray[-47] = subMember1Click
subMemberClickArray[-46] = subMember2Click
subMemberClickArray[-45] = subMember3Click

--Wait for cleanup variables and its respective functions, from 1st version of my messed up code^TM.
exchangeMode = 0
npClicked = 0
stageCount = 1
stageTurnArray = {0, 0, 0, 0, 0}
turnCounter = {0, 0, 0, 0, 0}

--Wait for cleanup variables and its respective functions, my messed up code^TM.
atkround = 1

--[[
recognize speed realated functions:
1.setScanInterval(1)
2.Settings:set("MinSimilarity", 0.5)
3.Settings:set("AutoWaitTimeout", 1)
4.usePreviousSnap(true)
5.resolution 1280
6.exists(var ,0)]]

function initCardPriorityArray()
	--[[
	Considering:
	Battle_CardPriority = "BAQ"
	
	then:
	CardPriorityArray = {"WB", "B", "RB", "WA", "A", "RA", "WQ", "Q", "RQ"}
	--]]
	local count = 0
	for card in Battle_CardPriority:gmatch(".") do
		table.insert(CardPriorityArray, "W" .. card)
		table.insert(CardPriorityArray, card)
		table.insert(CardPriorityArray, "R" .. card)
		
		count = count + 1
	end
end

function init()
	setImmersiveMode(true)			   
	Settings:setCompareDimension(true,1280)
	Settings:setScriptDimension(true,2560)
	
	--Set only ONCE for every separated script run.
	initCardPriorityArray()
	StoneUsed = 0
	RefillDialogueShown = 0
	AutoSkillParsedAndDialogueShown = 0
	
	--Check function CheckCurrentStage(region)
	StageCounter = 1
end

init()

function menu()
    atkround = 1
    npClicked = 0
    turnCounter = {0, 0, 0, 0, 0}
    click(Location(1900,400))
    wait(1.5)
    if Refill_or_Not == 1 and StoneUsed < How_Many then
        RefillStamina()
    end
    click(Location(1900,500))
    wait(1.5)
    click(Location(2400,1350))
	wait(8)
end

function RefillStamina()
    if StaminaRegion:exists("stamina.png", 0) then
        if Use_Stone == 1 then
			click(StoneClick)
			toast("Auto Refilling Stamina")
	    wait(1.5)
            click(Location(1650,1120))
            StoneUsed = StoneUsed + 1
        else
			click(AppleClick)
			toast("Auto Refilling Stamina")
	    wait(1.5)
            click(Location(1650,1120))
            StoneUsed = StoneUsed + 1
        end
		wait(3)
		if NotJPserverForStaminaRefillExtraClick == nil then
			--Temp solution, https://github.com/29988122/Fate-Grand-Order_Lua/issues/21#issuecomment-357257089 
			click(Location(1900,400))
			wait(1.5)
		end
    end
end

function battle()
	InitForCheckCurrentStage()

	--TBD: counter not used
	local RoundCounter = 1
	
	if TargetChoosen ~= 1 then
		--Choose priority target for NP spam and focuse fire.
		TargetChoose()
	end
	
    wait(0.5)
    if Enable_Autoskill == 1 then
		executeSkill()
    end
    
    wait(0.5)
	if npClicked == 0 then
		--enter card selection screen
    	click(Location(2300,1200))
    	wait(1)
    end
    
    if TargetChoosen == 1 and npClicked == 0 then
        ultcard()
    end

    wait(0.5)
    doBattleLogic()
    
    usePreviousSnap(false)
    
	atkround = atkround + 1

	--https://github.com/29988122/Fate-Grand-Order_Lua/issues/55 Experimental
	if UnstableFastSkipDeadAnimation == 1 then
		for i = 1, 6 do
			click(Location(1500,500))
			wait(2)
		end
	end
    wait(3)
end

function InitForCheckCurrentStage()
	--Generate a snapshot ONCE in the beginning of battle(). Will re-run itself after entered memu().
	if SnapshotGeneratedForStagecounter ~= 1 then
		wait(2)
		StageCountRegion:save("_GeneratedStageCounterSnapshot.png")		
		SnapshotGeneratedForStagecounter = 1
		StageCounter = 1
	end
end

function TargetChoose()
    t1 = Target1Type:exists("target_servant.png")
	usePreviousSnap(true)
	t2 = Target2Type:exists("target_servant.png")
	t3 = Target3Type:exists("target_servant.png")
	t1a = Target1Type:exists("target_danger.png")
	t2a = Target2Type:exists("target_danger.png")
	t3a = Target3Type:exists("target_danger.png")
    if t1 ~= nil or t1a ~= nil then
        click(Target1Choose)
		toast("Switched to priority target")
		TargetChoosen = 1
	elseif t2 ~= nil or t2a ~= nil then
		click(Target2Choose)
		toast("Switched to priority target")
		TargetChoosen = 1
	elseif t3 ~= nil or t3a ~= nil then
		click(Target3Choose)
		toast("Switched to priority target")
		TargetChoosen = 1
	else
		toast("No priority target selected")
    end
    usePreviousSnap(false)
end

function executeSkill()
	npClicked = 0
	local currentStage = 1
	local currentTurn = atkround
	if stageCount ~= 1 then
    		currentStage = CheckCurrentStage(StageCountRegion)
    		turnCounter[currentStage] = turnCounter[currentStage] + 1
    		currentTurn = turnCounter[currentStage]
    end
    	
    if currentTurn	<= stageTurnArray[currentStage] then 		
    	local currentSkill = stageSkillArray[currentStage][currentTurn]
    	local firstSkill = 1
    	if currentSkill ~= '0' and currentSkill ~= '#' then
    		for command in string.gmatch(currentSkill, ".") do
        		decodeSkill(command, firstSkill)
        		firstSkill = 0	
        	end
    	end
    	usePreviousSnap(false)
		if npClicked == 0 then
			--wait for last iterated skill animation
    		wait(3)
    	end	
    end
    usePreviousSnap(false)
end

function CheckCurrentStage(region)
	--Alternative fix for different font of stagecount number among different regions, worked pretty damn well tho.
	--This will compare last screenshot with current screen, effectively get to know if stage changed or not.
	local s = region:exists(Pattern("_GeneratedStageCounterSnapshot.png"):similar(0.8))

	--Pattern found, stage did not change.
	if s ~= nil then
		toast("Battle "..StageCounter.."/3")
		return StageCounter
	end
	
	--Pattern not found, which means that stage changed. Generate another snapshot te be used next time.
	if s == nil then
		StageCountRegion:save("_GeneratedStageCounterSnapshot.png")
		StageCounter = StageCounter + 1
		toast("Battle "..StageCounter.."/3")
		return StageCounter
	end
end
	
function decodeSkill(str, isFirstSkill)
	--magic number - check ascii code, a == 97
	local index = string.byte(str) - 96
	if isFirstSkill == 0 and npClicked == 0 and index >= -44 and exchangeMode == 0 then
		--wait for skill animation
		wait(3)
	end
	--enter Order Change Mode
	if index == 24 then
		exchangeMode = 1
	end
	if index >= 10 then
		--cast master skill
		 click(Location(2380, 640))
		 wait(0.3)
	end
	if index >= -44 and index <= -42 and npClicked == 0 then
		---cast NP
		click(Location(2300,1200))
		npClicked = 1
		wait(1)
	end
	--iterate, cast skills/NPs, also select target for it(if needed)
	if exchangeMode == 1 then
		click(SkillClickArray[12])
		exchangeMode = 2
	elseif exchangeMode == 2 then
		click(startingMemberClickArray[index])
		exchangeMode = 3
	elseif exchangeMode == 3 then
		click(subMemberClickArray[index])
		wait(0.3)
		click(Location(1280,1260))
		exchangeMode = 0
		wait(4)
	else
		click(SkillClickArray[index])
	end
	if index > 0 and Skill_Confirmation == 1 then
		click(Location(1680,850))
	end
end	

function checkCardAffin(region)
	weakAvail = region:exists("weak.png")
	usePreviousSnap(true)
	if weakAvail ~= nil then
		return WeakMulti
	end
	
	if region:exists("resist.png") ~= nil then
		return ResistMulti
	else
		return NormalMulti
	end	
end

function checkCardType(region)
	if region:exists("buster.png") ~= nil then
		return BCard
	end
	
	if region:exists("art.png") ~= nil then
		return ACard
	end
	
	if region:exists("quick.png") ~= nil then
		return QCard
	else
		return BCard
	end		
end

function ultcard()
	click(Ultcard1Click)
	click(Ultcard2Click)
	click(Ultcard3Click)
end

function doBattleLogic()	
	local cardStorage =
	{
		WB = {}, B = {}, RB = {},
		WA = {}, A = {}, RA = {},
		WQ = {}, Q = {}, RQ = {}
	}
	
	for cardSlot = 1, 5 do
		local cardAffinity = checkCardAffin(CardAffinRegionArray[cardSlot])
		local cardType = checkCardType(CardTypeRegionArray[cardSlot])
		local cardScore = cardAffinity * cardType
		
		if cardScore == WeakBuster then
			table.insert(cardStorage.WB, cardSlot)
		elseif cardScore == BCard then
			table.insert(cardStorage.B, cardSlot)
		elseif cardScore == ResistBuster then
			table.insert(cardStorage.RB, cardSlot)
			
		elseif cardScore == WeakArt then
			table.insert(cardStorage.WA, cardSlot)
		elseif cardScore == ACard then
			table.insert(cardStorage.A, cardSlot)
		elseif cardScore == ResistArt then
			table.insert(cardStorage.RA, cardSlot)	
			
		elseif cardScore == WeakQuick then
			table.insert(cardStorage.WQ, cardSlot)
		elseif cardScore == QCard then
			table.insert(cardStorage.Q, cardSlot)
		else
			table.insert(cardStorage.RQ, cardSlot)		
		end
	end
	
	local clickCount = 0
	for p, cardPriority in ipairs(CardPriorityArray) do
		local currentStorage = cardStorage[cardPriority]
	
		for s, cardSlot in pairs(currentStorage) do
			click(CardClickArray[cardSlot])
			clickCount = clickCount + 1
			
			if clickCount == 3 then
				break
			end
		end
		
		if clickCount == 3 then
			break
		end
	end	
end

--[[Deprecated
function norcard()
    i = 0
    
    w1 = CardAffinRegionArray[1]:exists("weak.png")
	usePreviousSnap(true)   
    if w1 ~= nil then
        click(Card1Click)
        Card1Clicked = 1
        i = i + 1
    end

    w2 = CardAffinRegionArray[2]:exists("weak.png")
    if w2 ~= nil then
        click(Card2Click)
        Card2Clicked = 1
        i = i + 1
    end

    w3 = CardAffinRegionArray[3]:exists("weak.png")
    if w3 ~= nil then
        click(Card3Click)
        Card3Clicked = 1
        i = i + 1
    end

    w4 = CardAffinRegionArray[4]:exists("weak.png")
    if w4 ~= nil then
        click(Card4Click)
        Card4Clicked = 1
        i = i + 1
    end

    w5 = CardAffinRegionArray[5]:exists("weak.png")
    if w5 ~= nil then
        click(Card5Click)
        Card5Clicked = 1
        i = i + 1
    end
end]]

function result()
    wait(2.5)
    click(Location(1000, 1000))
    wait(3.5)
    click(Location(1000, 1000))
    wait(3.5)
    click(Location(2200, 1350))
    if isEvent == 1 then
    	wait(2)
    	click(Location(2200, 1350))
    end
    wait(15)
	if QuestrewardRegion:exists("questreward.png") ~= nil then
		click(Location(100,100))
	end
end

function RefillDialogue()
	if Refill_or_Not == 1 and RefillDialogueShown == 0 then
		if Use_Stone == 1 then
			temp = "stones"
		else
			temp = "apples"
		end
		dialogInit()
		addTextView("You are going to use "..How_Many.." "..temp..", remember to check those values everytime you execute the script!")
		if Enable_Autoskill == 0 then
			--Finsishd dialogue construction, show it on screen. dialogShow("%title of box%")
			dialogShow("Auto Refill Enabled")
		end
		RefillDialogueShown = 1
	end
end

function AutoSkillDialogue()
	if Enable_Autoskill == 1 and AutoSkillParsedAndDialogueShown == 0 then
		if Refill_or_Not == 0 then
			dialogInit()
		else
			newRow()
		end
		addTextView("AutoSkill Enabled! Start the script from memu or Battle 1/3 to make it work properly. Make sure that your Skill Command is correct before you execute the script!")
		if Refill_or_Not == 0 then
			--Finsishd dialogue construction, show it on screen. dialogShow("%title of box%")
			dialogShow("AutoSkill Enabled")
		else
			--Finsishd dialogue construction, show it on screen. dialogShow("%title of box%")
			dialogShow("AutoSkill and Auto Refill Enabled")
		end
		for word in string.gmatch(Skill_Command, "[^,]+") do
  			if string.match(word, "[^0]") ~= nil then
    			if string.match(word, "^[1-3]") ~= nil then
      				scriptExit("Error at '" ..word.. "': Skill Command cannot start with number '1', '2' and '3'!")
      			elseif string.match(word, "[%w+][#]") ~= nil or string.match(word, "[#][%w+]") ~= nil then
      				scriptExit("Error at '" ..word.. "': '#' must be preceded and followed by ','! Correct: ',#,' ")
    			elseif string.match(word, "[^a-l^1-6^#^x]") ~= nil then
        			scriptExit("Error at '" ..word.. "': Skill Command exceeded alphanumeric range! Expected 'x' or range 'a' to 'l' for alphabets and '0' to '6' for numbers.")
        		end
    		end
  			if word == '#' then
    			stageCount = stageCount + 1
    			if stageCount > 5 then
    		  		scriptExit("Error: Detected commands for more than 5 stages")
    			end
    		end
    		if word ~= '#' then
    			table.insert(stageSkillArray[stageCount], word)
    			stageTurnArray[stageCount] = stageTurnArray[stageCount] + 1
    		end
  		end
		AutoSkillParsedAndDialogueShown = 1
	end
end

while(1) do
	--Execute only once
	RefillDialogue()
	AutoSkillDialogue()
	
    if MenuRegion:exists("menu.png", 0) then
		toast("Will only select servant/danger enemy as noble phantasm target, unless specified using Skill Command. Please check github for further detail.")
        menu()
		TargetChoosen = 0

		SnapshotGeneratedForStagecounter = 0
    end
    if BattleRegion:exists("battle.png", 0) then
        battle()
    end
    if ResultRegion:exists("result.png", 0) then
        result()
    end
end
