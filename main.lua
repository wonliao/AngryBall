-- 隱藏狀態 bar
display.setStatusBar( display.HiddenStatusBar )
local sprite = require( "sprite" )

-- 設定 物理效果
local physics = require("physics")
physics.start()
physics.setScale( 60 ) -- a value that seems good for small objects (based on playtesting)
physics.setGravity( 0, 0 ) -- overhead view, therefore no gravity vector

-- 球的物理效果
local ballBody = { density=0.2, friction=1.0, bounce=1, radius=40 }

-- 音效
local collisionAudio = audio.loadSound("audio/ballsCollide.mp3") 


local visual
local stage = 1
local selectIndex = 0
local characterTable = {}   -- 角色
local monsterTable = {}     -- 怪物
local hpTable = {}          -- 怪物血量

                       
-- 設置場景
function gameStage()

        -- 底圖
        lime = require("lime.lime")
        local map = lime.loadMap("dest.tmx")
        visual = lime.createVisual(map)
        visual.y = -1450
        visual.xScale = 1.01

        -- 底部界面
	local table = display.newImageRect( "image/table_bkg.png", 768, 1024) -- "true" overrides Corona's downsizing of large images on smaller devices
	table.x = 384
	table.y = 512

        -- 設定4個邊界
        -- 上
        local bumper1 = display.newImageRect( "image/bumper_end.png", display.contentWidth, 0 )
        bumper1.name = "wall"
	physics.addBody( bumper1, "static", { friction=0.5, bounce=0.3 } )
	bumper1.x = display.contentWidth/2; bumper1.y = 0

        -- 下
        local bumper2 = display.newImageRect( "image/bumper_end.png", display.contentWidth, 0 )
        bumper2.name = "wall"
	physics.addBody( bumper2, "static", { friction=0.5, bounce=0.3 } )
	bumper2.x = display.contentWidth/2; bumper2.y = display.contentHeight - 220

        -- 左
        local bumper3 = display.newImageRect( "image/bumper_side.png", 0, display.contentHeight )
        bumper3.name = "wall"
	physics.addBody( bumper3, "static", { friction=0.5, bounce=0.3 } )
	bumper3.x = 0; bumper3.y = display.contentHeight/2

        -- 右
        local bumper4 = display.newImageRect( "image/bumper_side.png", 0, display.contentHeight )
        bumper4.name = "wall"
	physics.addBody( bumper4, "static", { friction=0.5, bounce=0.3 } )
	bumper4.x = display.contentWidth; bumper4.y = display.contentHeight/2
end

-- 設定球的屬性
function ballProperties()

        stage = 1
        selectIndex = 0

	local v = 0
	local reqForce = .18
	local maxBallSounds = 4

        -- 怪物
        local monsterCount = 4

        function onCollision( self, event )

                if ( event.phase == "began" ) then

                        local bAudio = audio.loadSound("audio/b.mp3")
                        audio.play(bAudio)

                        -- 目標為怪物時
                        if string.find(event.other.name, "monster") ~= nil then

                            -- 爆炸特效
                            explosion(event.other.x, event.other.y)

                            -- 扣血量
                            local n = event.other.id
                            widthReduce = 30
                            if hpTable[n].width >= widthReduce then

                                    hpTable[n].width = hpTable[n].width - widthReduce
                                    hpTable[n].x = hpTable[n].x - widthReduce
                            else
                                    -- 血量為 0時，刪除物件
                                    print("delete monster n("..n..")")

                                    hpTable[n].isVisible = false

                                    event.other:removeSelf()
                                    event.other = nil;
                                    --physics.removeBody( event.other )

                                    -- 過關
                                    monsterCount = monsterCount - 1
                                    if monsterCount <= 0 then

                                            stage = stage + 1                                
                                            print("stage("..stage..")")
                                            -- 移動地圖
                                            if stage == 2 then
                
                                                transition.to( visual, {time=5000, y=-550} )
                                                
                                                -- 準備場景上的怪物
                                                timer.performWithDelay(5000, function() initEnemyByStage() end, 1)
                                            elseif stage == 3 then

                                                transition.to( visual, {time=5000, y=0} )

                                                -- 準備場景上的怪物
                                                timer.performWithDelay(5000, function() initEnemyByStage() end, 1)
                                            elseif stage == 4 then
                                            
                                                youWin = display.newImageRect( "you-win.gif", 768, 360)
                                                youWin.x = 384
                                                youWin.y = 400

                                                -- 重置鈕
                                                --refresh = display.newImageRect( "image/refresh.png", 305/1.5, 280/1.5)
                                                --refresh.x = 384
                                                --refresh.y = 700

                                               
                                            end
                                    end
                            end
                        end
                elseif ( event.phase == "ended" ) then

                         --print( "ended => "..self.name .. ": collision began with " .. event.other.name )
                end
        end

        -- 刪除角色
        for _, character in ipairs( characterTable ) do

                character:removeSelf()
                character = nil
        end
        characterTable = {}

	-- 產生角色
        function createCharacter(n, img, posX, posY)

                characterTable[n] = display.newImage(img)
                physics.addBody( characterTable[n], ballBody )
                characterTable[n].x = posX; characterTable[n].y = posY
                characterTable[n].name = "character_"..n
                characterTable[n].linearDamping = 0.8
                characterTable[n].angularDamping = 0.8
                characterTable[n].isBullet = true -- force continuous collision detection, to stop really fast shots from passing through other balls
                characterTable[n].type = "cueBall"
                characterTable[n].collision = onCollision
                characterTable[n]:addEventListener("collision", characterTable[n]) -- Sprite balls start animation on Collision with cueball
                characterTable[n]:addEventListener( "postCollision", characterTable[n] )
                characterTable[n].isFixedRotation = true
        end

        -- 產生4位角色
        createCharacter(1, "image/c1.png", 130, 700)
        createCharacter(2, "image/c2.png", 300, 750)
        createCharacter(3, "image/c3.png", 450, 700)
        createCharacter(4, "image/c4.png", 620, 750)

        -- 產生 選定框
        local focusTarget = display.newImage( "image/target.png" )

        -- 旋轉 選定框
        startRotation = function()
                focusTarget.rotation = focusTarget.rotation + 4
                focusTarget.x = characterTable[selectIndex].x; focusTarget.y = characterTable[selectIndex].y;
        end
        Runtime:addEventListener( "enterFrame", startRotation )

        -- 設定 選定框的目標
        function setFocus()

            if selectIndex > 0 then characterTable[selectIndex]:removeEventListener( "touch", cueShot ) end

            selectIndex = selectIndex + 1;
            if selectIndex > 4 then selectIndex = 1 end

            characterTable[selectIndex]:addEventListener( "touch", cueShot )
            focusTarget.x = characterTable[selectIndex].x; focusTarget.y = characterTable[selectIndex].y; focusTarget.alpha = 1;
        end

        -- 設定 選定框的目標
        setFocus()


        -- 生成怪物
        function createEnemy( n, img, posX, posY )

                monsterTable[n] = display.newImage(img)
		physics.addBody(monsterTable[n], "static", ballBody)
		monsterTable[n].x = posX 
		monsterTable[n].y = posY
		monsterTable[n].linearDamping = 0.3 -- simulates friction of felt
		monsterTable[n].angularDamping = 2 -- stops balls from spinning forever
		monsterTable[n].isBullet = true -- If true physics body always awake
		monsterTable[n].active = true -- Ball is set to active
		monsterTable[n].bullet = false -- force continuous collision detection, to stop really fast shots from passing through other balls
		monsterTable[n].name = "monster_"..n --"spriteBall"
		monsterTable[n]:addEventListener( "postCollision", monsterTable[n] )
                monsterTable[n].id = n

                -- 血量條
                hpTable[n] = display.newImage( "image/hp.png" )
                hpTable[n]:scale( 2, 4 )
                hpTable[n].x = posX

                -- 血量條座標
                if img == "image/ball_4.png" then 
                        hpTable[n].y = posY + 100   -- 魔王
                else
                        hpTable[n].y = posY + 60    -- 小兵
                end
                
                 print("add monsterTable("..#monsterTable..")")
	end

        -- 準備場景上的怪物
        function initEnemyByStage()

                print("monsterTable("..#monsterTable..")")
                
                -- 刪除怪物
                monsterTable = {}

                if stage == 1 then

                    monsterCount = 4
                    createEnemy(1, "image/ball_1.png", 200, 300)
                    createEnemy(2, "image/ball_1.png", 600, 300)
                    createEnemy(3, "image/ball_2.png", 400, 150)
                    createEnemy(4, "image/ball_3.png", 400, 450)
                elseif stage == 2 then

                    monsterCount = 5
                    createEnemy(1, "image/ball_1.png", 200, 200)
                    createEnemy(2, "image/ball_1.png", 300, 300)
                    createEnemy(3, "image/ball_2.png", 400, 400)
                    createEnemy(4, "image/ball_2.png", 500, 500)
                    createEnemy(5, "image/ball_2.png", 600, 600)
                elseif stage == 3 then

                    monsterCount = 5
                    createEnemy(1, "image/ball_1.png", 600, 150)
                    createEnemy(2, "image/ball_2.png", 200, 150)
                    createEnemy(3, "image/ball_4.png", 400, 300)
                    createEnemy(4, "image/ball_3.png", 600, 450)
                    createEnemy(5, "image/ball_3.png", 200, 450)
                end
        end

        -- 準備場景上的怪物
        initEnemyByStage()
end
    
-- Shoot the cue ball, using a visible force vector
function cueShot( event )

	local t = event.target
	local phase = event.phase

	if "began" == phase then

		display.getCurrentStage():setFocus( t )
		t.isFocus = true

		t:setLinearVelocity( 0, 0 )
		t.angularVelocity = 0

		myLine = nil
	elseif t.isFocus then

		if "moved" == phase then

			if ( myLine ) then
				myLine.parent:remove( myLine ) -- erase previous line, if any
			end
			myLine = display.newLine( t.x,t.y, event.x,event.y )
			myLine:setColor( 255, 255, 255, 50 )
			myLine.width = 15
		elseif "ended" == phase or "cancelled" == phase then

			display.getCurrentStage():setFocus( nil )
			t.isFocus = false

			local stopRotation = function()
				Runtime:removeEventListener( "enterFrame", startRotation )
			end
			local hideTarget = transition.to( target, { alpha=0, xScale=1.0, yScale=1.0, time=200, onComplete=stopRotation } )

			if ( myLine ) then  myLine.parent:remove( myLine )  end

			-- Strike the ball!
			local strikeAudio = audio.loadSound("audio/t.mp3")
			audio.play(strikeAudio)
			t:applyForce( (t.x - event.x), (t.y - event.y), t.x, t.y )

                        setFocus()
		end
	end

	return true	-- Stop further propagation of touch event
end

-- 爆炸特效
function explosion(posX, posy)

        local sprite = require("sprite")
        local explosionSheet = sprite.newSpriteSheet("image/explosion_43FR.png", 93, 100)
        local explosionSet = sprite.newSpriteSet(explosionSheet, 1, 40)
        sprite.add(explosionSet, "explosion", 1, 40, 30, 1)
        local explosion = sprite.newSprite(explosionSet)
        explosion:setReferencePoint(display.CenterReferencePoint)
        explosion.x = posX
        explosion.y = posy
        explosion.xScale = 2
        explosion.yScale = 2
        explosion:prepare("explosion")
        explosion:play()
end

-- 設定場景
gameStage()
 
-- 設定球的屬性
ballProperties()




 