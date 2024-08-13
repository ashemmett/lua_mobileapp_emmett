-----------------------------------------------------------------------------------------
--
-- menuScene.lua | Ashton Emmett 10564416 | MAD Project 
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local widget = require("widget")
local scene = composer.newScene()

local function goToGoLScene(event)
    if event.phase == "ended" then
        composer.gotoScene("GoLscene", { effect = "slideLeft", time = 500 })
    end
end

function scene:create(event)
    local sceneGroup = self.view

    -- Create title text
    local titleText = display.newText(sceneGroup, "Game of Life Simulation", display.contentCenterX, -30, native.systemFontBold, 24)
    titleText:setFillColor(1, 1, 1)  -- Set text color to white

    -- Create "Start" button
    local startButton = widget.newButton {
        label = "Start",
        labelColor = { default = { 1, 1, 1 }, over = { 0, 1, 0 } },
        onEvent = goToGoLScene,
        emboss = false,
        shape = "roundedRect",
        width = 300,
        height = 50,
        cornerRadius = 10,
        fillColor = { default = { 0, 1, 0  }, over = { 0, 1, 0  } },
    }
    startButton.x = display.contentCenterX
    startButton.y = display.contentCenterY - 200
    sceneGroup:insert(startButton)
end

-- Add event listeners
scene:addEventListener("create", scene)

return scene