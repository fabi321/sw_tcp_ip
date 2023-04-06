error('This module is not intended to be require\'d')

---@class input
input = {}

--- Read values from the composite input. Index ranges from 1 - 32.
---@param index number
---@return number
function input.getNumber(index) end

--- Read values from the composite input. Index ranges from 1 - 32.
---@param index number
---@return boolean
function input.getBool(index) end

---@class output
output = {}

--- Set values on the composite input. Index ranges from 1 - 32.
---@param index number
---@param value number
function output.setNumber(index, value) end

--- Set values on the composite input. Index ranges from 1 - 32.
---@param index number
---@param value boolean
function output.setBool(index, value) end

---@class property
property = {}

--- Read the values of property components within this microcontroller directly. The label passed to each function
--- should match the label that has been set for the property you're trying to access (case-sensitive).
---@param label string
---@return number
function property.getNumber(label) end

--- Read the values of property components within this microcontroller directly. The label passed to each function
--- should match the label that has been set for the property you're trying to access (case-sensitive).
---@param label string
---@return boolean
function property.getBool(label) end

--- Read the values of property components within this microcontroller directly. The label passed to each function
--- should match the label that has been set for the property you're trying to access (case-sensitive).
---@param label string
---@return string
function property.getText(label) end

---@class screen
screen = {}

--- Set the current draw color. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setColor(r, g, b, a) end

--- Clear the screen with the current colour.
function screen.drawClear() end

--- Draw line from (x1, y1) to (x2, y2).
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function screen.drawLine(x1, y1, x2, y2) end

--- Draw circle at (x, y) with radius
---@param x number
---@param y number
---@param radius number
function screen.drawCircle(x, y, radius) end

--- Draw filled circle at (x, y) with radius
---@param x number
---@param y number
---@param radius number
function screen.drawCircleF(x, y, radius) end

--- Draw rectangle at (x, y) with width and height
---@param x number
---@param y number
---@param width number
---@param height number
function screen.drawRect(x, y, width, height) end

--- Draw filled rectangle at (x, y) with width and height
---@param x number
---@param y number
---@param width number
---@param height number
function screen.drawRectF(x, y, width, height) end

--- Draw triangle between (x1, y1), (x2, y2) and (x3, y3)
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
function screen.drawTriangle(x1, y1, x2, y2, x3, y3) end

--- Draw filled triangle between (x1, y1), (x2, y2) and (x3, y3)
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@param x3 number
---@param y3 number
function screen.drawTriangleF(x1, y1, x2, y2, x3, y3) end

--- Draw text at (x, y). Each character is 4 pixels wide and 5 pixels tall.
---@param x number
---@param y number
---@param text string
function screen.drawText(x, y, text) end

--- Draw text within the rectangle at (x, y) with width and height. Text alignment can be specified using the last two
--- parameters and range from -1 to 1 (left to right, top to bottom). If either of the alignment parameters are omitted,
--- the text will be drawn top-left by default. Text will automatically wrap at spaces when possible, and will overflow
--- the top/bottom of the specified rectangle if too large.
---@overload fun(x: number, y: number, w: number, h: number, text: string)
---@overload fun(x: number, y: number, w: number, h: number, text: string, h_align: number | nil)
---@param x number
---@param y number
---@param w number
---@param h number
---@param text string
---@param h_align number | nil
---@param v_align number | nil
function screen.drawTextBox(x, y, w, h, text, h_align, v_align) end

--- Draw the world map centered on map coordinate (x, y) with zoom level ranging from 0.1 to 50.
---@param x number
---@param y number
---@param zoom number
function screen.drawMap(x, y, zoom) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorOcean(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorShallows(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorLand(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorGrass(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorSand(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorSnow(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorRock(r, g, b, a) end

--- Set the colors used for rendering the map. Values range from 0 - 255, alpha is optional.
---@overload fun(r: number, g: number, b: number)
---@param r number
---@param g number
---@param b number
---@param a number | nil
function screen.setMapColorGravel(r, g, b, a) end

--- Get the width of the screen currently being rendered to.
---@return number
function screen.getWidth() end

--- Get the height of the screen currently being rendered to.
---@return number
function screen.getHeight() end

---@class map
map = {}

--- Convert pixel coordinates into world coordinates
---@param mapX number
---@param mapY number
---@param zoom number
---@param screenW number
---@param screenH number
---@param pixelX number
---@param pixelY number
---@return number, number
function map.screenToMap(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY) end

--- Convert world coordinates into pixel coordinates
---@param mapX number
---@param mapY number
---@param zoom number
---@param screenW number
---@param screenH number
---@param worldX number
---@param worldY number
---@return number, number
function map.screenToMap(mapX, mapY, zoom, screenW, screenH, worldX, worldY) end

---@class async
async = {}

--- Http requests are sent to the localhost on the specified port. Responses are caught with the
--- httpReply(port, request_body, response_body) callback function.
---@param port number
---@param request_body string
function async.httpGet(port, request_body) end
