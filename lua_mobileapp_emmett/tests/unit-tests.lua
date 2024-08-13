module(..., package.seeall)

local require("GoLscene.lua")

-- test CreateMatrix
function testCreateMatrix()
    local size = 3
    local matrix = mymodule.CreateMatrix(size)

    -- Check if the matrix is a table
    lunatest.assert_table(matrix)

    -- Check correct size
    lunatest.assert_equal(size, #matrix)
end

-- test GoLRules
function testGoLRules()
end

-- test RandomAliveCells
function testRandomAliveCells()
end