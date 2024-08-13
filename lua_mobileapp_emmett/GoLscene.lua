----------------------------------------------------------------------------------------
--
-- GoLscene.lua | Ashton Emmett 10564416 | MAD Project 
--
----------------------------------------------------------------------------------------
local composer = require( "composer" )
local widget = require("widget")
local scene = composer.newScene()
local timerID
local matrix 
local size = enteredState
local enteredAliveCells = 0
local isPaused = true

----------------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
----------------------------------------------------------------------------------------

-- Create matrix function ----------------------------------------------------------------------------------------
function CreateMatrix(size)
    local matrix = {}
    for rows = 1, size do
        matrix[rows] = {}
        for columns = 1, size do
            matrix[rows][columns] = 0
        end
    end
    return matrix
end

-- Create random Alive cells ----------------------------------------------------------------------------------------
function randomalivecells(matrix, numAliveCells)
    math.randomseed(os.time()) -- random generator using time

    local size = #matrix
    local aliveCells = 0

    while aliveCells < numAliveCells do
        local row = math.random(1, size)
        local column = math.random(1, size)
        if matrix[row][column] == 0 then
            matrix[row][column] = 1
            aliveCells = aliveCells + 1
        end
    end
end

-- GolRules ----------------------------------------------------------------------------------------
function GoLRules(matrix)
    local numRows = #matrix
    local numCols = #matrix[1]

    local newMatrix = {}
    for row = 1, numRows do
        newMatrix[row] = {}
        for column = 1, numCols do
            newMatrix[row][column] = 0
        end
    end
    -- neighboring cells detection
    local neighboringCells = {
        {-1, -1}, {-1, 0}, {-1, 1},
        {0, -1},           {0, 1},
        {1, -1}, {1, 0}, {1, 1}
    }

    for row = 1, numRows do
        for column = 1, numCols do
            local aliveNeighbours = 0
            for _, neighbour in ipairs(neighboringCells) do
                local newRow = (row + neighbour[1] - 1) % numRows + 1
                local newColumn = (column + neighbour[2] - 1) % numCols + 1
                aliveNeighbours = aliveNeighbours + (matrix[newRow][newColumn] == 1 and 1 or 0)
            end

            if matrix[row][column] == 1 then
                if aliveNeighbours == 2 or aliveNeighbours == 3 then
                    newMatrix[row][column] = 1
                end
            else
                if aliveNeighbours == 3 then
                    newMatrix[row][column] = 1
                end
            end
        end
    end

    return newMatrix
end

-- Stop ----------------------------------------------------------------------------------------
function clearMatrix()
    for rows = 1, size do
        for columns = 1, size do
            matrix[rows][columns] = 0
        end
    end
end

function stop(event)
    if timerID then
        timer.cancel(timerID) -- Cancel the timer to stop the simulation
        clearMatrix() -- Make all cells dead
        displayMatrix(matrix) -- Update the display
    end
end

-- Pause ----------------------------------------------------------------------------------------
function pause(event)
    if isPaused then
        timer.resume(timerID) -- resume (unpause)
        isPaused = false
    else
        timer.pause(timerID) -- pause
        isPaused = true
    end
end

-- Restart application (go back to menuScene) ----------------------------------------------------------------------------------------
function gotoMenuScene()
    composer.removeScene("GoLscene", true)
    composer.gotoScene("menuScene", { effect = "slideRight", time = 500 })
    return true 
end

-- Restart ----------------------------------------------------------------------------------------
function restart(event)
    isPaused = false -- Unpause the simulation
    matrix = CreateMatrix(size)
    randomalivecells(matrix, enteredAliveCells)
    displayMatrix(matrix)
    timerID = timer.performWithDelay(100, updateDisplay, 0)
end

-- Save ----------------------------------------------------------------------------------------
function save(event)
    local path = system.pathForFile("simulation.csv", system.DocumentsDirectory)
    local file, errorString = io.open(path, "w")
    if not file then
        print("Error: " .. errorString)
        return
    end
    -- Write the matrix data to the CSV file 
    for row = 1, #matrix do
        local rowData = table.concat(matrix[row], ",")
        file:write(rowData .. "\n")
    end
    io.close(file)
end

-- Restore ----------------------------------------------------------------------------------------
function restore(event)
    local path = system.pathForFile("simulation.csv", system.DocumentsDirectory)
    local file, errorString = io.open(path, "r")
    if not file then
        print("Error: " .. errorString)
        return
    end

    local restoredMatrix = {}
    for line in file:lines() do
        local rowData = {}
        for value in line:gmatch("[^,]+") do
            table.insert(rowData, tonumber(value))
        end
        table.insert(restoredMatrix, rowData)
        print('restored')
    end
    io.close(file)
    matrix = restoredMatrix
    updateDisplay()
end

-- Begin ----------------------------------------------------------------------------------------
function begin(event)
    isPaused = false -- Unpause the simulation
    matrix = CreateMatrix(size)
    randomalivecells(matrix, enteredAliveCells)
    displayMatrix(matrix)
    -- Clear the timer
    if timerID then
        timer.cancel(timerID)
    end
    timerID = timer.performWithDelay(100, updateDisplay, 0)
end

-- Random ----------------------------------------------------------------------------------------
function random(event) 

    isPaused = true
    local randomState = math.random(5, 200) -- random from 5 to 200 size
    local randomAliveCells = math.random(5, 5000) -- random from 5 to 5000 alive cells
    -- Call the updateMatrixBasedOnState
    updateMatrixBasedOnState(randomState, randomAliveCells)
end

----------------------------------------------------------------------------------------
-- Scene event functions
----------------------------------------------------------------------------------------

-- create()
function scene:create( event )
    local sceneGroup = self.view

    -- DisplayMatrix Function  ----------------------------------------------------------------------------------------
    local displayContentSize = { width = 280, height = 280 }
    local cellRectangles = {}

    function displayMatrix(matrix)
        local numRows = #matrix
        local numCols = #matrix[1]

        local startX = (display.contentWidth - displayContentSize.width) / 2
        local startY = 0

        local cellWidth = displayContentSize.width / numCols
        local cellHeight = displayContentSize.height / numRows

        for row = 1, numRows do
            for column = 1, numCols do
                local x = startX + (column - 1) * cellWidth
                local y = startY + (row - 1) * cellHeight

                if matrix[row][column] == 1 then
                    if not cellRectangles[row] or not cellRectangles[row][column] then
                        local rect = display.newRect(sceneGroup, x, y, cellWidth, cellHeight)
                        rect.anchorX, rect.anchorY = 0, 0
                        rect:setFillColor(0, 1, 0)  -- Green for alive cells

                        cellRectangles[row] = cellRectangles[row] or {}
                        cellRectangles[row][column] = rect
                    end
                elseif matrix[row][column] == 0 then
                    if cellRectangles[row] and cellRectangles[row][column] then
                        local rect = cellRectangles[row][column]

                        -- Remove the dead cells
                        display.remove(rect)
                        cellRectangles[row][column] = nil
                    end
                end
            end
        end
    end

    -- update display based upon GoLrules  ----------------------------------------------------------------------------------------
    function updateDisplay()
        -- paused by default
        displayMatrix(matrix)
        matrix = GoLRules(matrix)
    end

    -- Input starting size/state ----------------------------------------------------------------------------------------
    local function inputStartingState(event)
        if event.phase == "ended" or event.phase == "submitted" then
            local enteredState = tonumber(event.target.text)
    
            updateMatrixBasedOnState(enteredState, enteredAliveCells)
        end
    end
    -- Create a text field for user input (size) 
    local sizeInput = native.newTextField(display.contentCenterX - 50, display.contentCenterY - 300, 200, 30)
    sizeInput.placeholder = "Enter starting state/size:"
    sizeInput:addEventListener("userInput", inputStartingState)
    sceneGroup:insert(sizeInput)

    -- Input starting alive cells ----------------------------------------------------------------------------------------
    local function inputStartingCells(event)
        if event.phase == "ended" or event.phase == "submitted" then
            enteredAliveCells = tonumber(event.target.text)
            updateMatrixBasedOnState(enteredState, enteredAliveCells)
        end
    end
    -- Create a text field for user input (alive cells)
    local aliveInput = native.newTextField(display.contentCenterX - 50, display.contentCenterY - 275, 200, 30)
    aliveInput.placeholder = "Enter amount of alive cells:"
    aliveInput:addEventListener("userInput", inputStartingCells)
    sceneGroup:insert(aliveInput)


    -- Update matrix state based on amount of cells and size  ----------------------------------------------------------------------------------------
    function updateMatrixBasedOnState(sizeInputText, aliveCellsInputText)
        if sizeInputText then
            size = tonumber(sizeInputText) or size
        end
        if aliveCellsInputText then
            local enteredAliveCells = tonumber(aliveCellsInputText)
            if enteredAliveCells then
                matrix = CreateMatrix(size) -- Create a new matrix with the entered size
                randomalivecells(matrix, enteredAliveCells)
            end
        else
            matrix = CreateMatrix(size) -- Create a new matrix with the current size
            randomalivecells(matrix, 5000) -- Set the default number of alive cells
        end
    end
    
    -- Begin  ----------------------------------------------------------------------------------------
    local beginButton = widget.newButton({
        label = "Begin",
        x = display.contentCenterX + 100,
        y = display.contentCenterY - 300,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={0, 1, 0}, over={0, 1, 0} }, -- Blue
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 18,
        onPress = begin,
    })
    sceneGroup:insert(beginButton)

    -- Stop simulation  ----------------------------------------------------------------------------------------
    local stopButton = widget.newButton({
        label = "Stop",
        x = display.contentCenterX - 75,
        y = display.contentCenterY + 100,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={1, 0, 0}, over={1, 0, 0.5} }, -- Red 
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 20,
        onPress = stop,
    })
    sceneGroup:insert(stopButton)

    -- Pause simulation  ----------------------------------------------------------------------------------------
    local pauseButton = widget.newButton({
        label = "Pause",
        x = display.contentCenterX - 75,
        y = display.contentCenterY + 150,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={1, 0.5, 0}, over={1, 0.5, 0.5} }, -- Orange 
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 20,
        onPress = pause,
    })
    sceneGroup:insert(pauseButton)

    -- Restart simulation  ----------------------------------------------------------------------------------------
    local restartButton = widget.newButton({
        label = "Restart",
        x = display.contentCenterX - 75,
        y = display.contentCenterY + 200,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={1, 1, 0}, over={1, 1, 0} }, -- Yellow 
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 20,
        onPress = restart,
    })
    sceneGroup:insert(restartButton)

    -- Save state  ----------------------------------------------------------------------------------------
    local saveButton = widget.newButton({
        label = "Save",
        x = display.contentCenterX + 75,
        y = display.contentCenterY + 100,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={0, 0.5, 0}, over={0, 0.3, 0} }, -- Dark Green 
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 20,
        onPress = save,
    })
    sceneGroup:insert(saveButton)

    -- Import/Restore state  ----------------------------------------------------------------------------------------
    local restoreButton = widget.newButton({
        label = "Restore",
        x = display.contentCenterX + 75,
        y = display.contentCenterY + 150,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={0, 0, 1}, over={0, 0, 0.5} }, -- Blue
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 20,
        onPress = restore,
    })
    sceneGroup:insert(restoreButton)

    -- Random input  ----------------------------------------------------------------------------------------
    local randomButton = widget.newButton({
        label = "Random",
        x = display.contentCenterX + 75,
        y = display.contentCenterY + 200,
        shape = "roundedRect",
        width = 80,
        height = 40,
        cornerRadius = 10,
        fillColor = { default={0, 0, 0.7}, over={0, 0, 0.2} }, -- Blue
        labelColor = { default={1, 1, 1} }, -- White Text
        font = native.systemFontBold,
        fontSize = 15,
        onPress = random,
    })
    sceneGroup:insert(randomButton)

    
    -- Iteration speed slider  ----------------------------------------------------------------------------------------
    local slider
    local sliderLabel = display.newText({
        text = "Iteration Speed",
        x = display.contentCenterX - 50,
        y = display.contentCenterY + 275,
        font = native.systemFontBold,
        fontSize = 18,
    })
    sceneGroup:insert(sliderLabel)

    slider = widget.newSlider({
        x = display.contentCenterX,
        y = display.contentCenterY + 250,
        width = 200,
        value = 1,  -- Initial value
    })
    sceneGroup:insert(slider)

    -- Restart application (go back)  ----------------------------------------------------------------------------------------
    local backButton = display.newText(sceneGroup, "Back", display.contentWidth - 20, -12.5, native.systemFont, 18)
    backButton:setFillColor(1, 0, 0) -- Red 
    backButton:addEventListener("tap", gotoMenuScene)
    sceneGroup:insert(backButton)
end

----------------------------------------------------------------------------------------
-- Scene event function listeners
----------------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

----------------------------------------------------------------------------------------

return scene