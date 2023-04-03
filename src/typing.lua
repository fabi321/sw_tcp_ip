error('This module is not intended to be require\'d')

---@class Input
---@field getNumber fun(index: number): number
---@field getBool fun(index: number): number
input = {}

---@class Output
---@field setNumber fun(index: number, value: number)
---@field setBool fun(index: number, value: boolean)
output = {}

---@class Property
---@field getNumber fun(label: string): number
---@field getBool fun(label: string): boolean
---@field getText fun(label: string): string
property = {}

---@class Screen
---@field setColor fun(r: number, g: number, b: number, a: number | nil)
---@field drawClear fun()
---@field drawLine fun(x1: number, y1: number, x2: number, y2: number)
---@field drawCircle fun(x: number, y: number, radius: number)
---@field drawCircleF fun(x: number, y: number, radius: number)
---@field drawRect fun(x: number, y: number, width: number, height: number)
---@field drawRectF fun(x: number, y: number, width: number, height: number)
---@field drawTriangle fun(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number)
---@field drawTriangleF fun(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number)
---@field drawText fun(x: number, y: number, text: string)
---@field drawTextBox fun(x: number, y: number, w: number, h: number, text: string, h_align: number | nil, v_align: number | nil)
---@field drawMap fun(x: number, y: number, zoom: number)
---@field setMapColorOcean fun(r: number, g: number, b: number, a: number)
---@field setMapColorShallows fun(r: number, g: number, b: number, a: number)
---@field setMapColorLand fun(r: number, g: number, b: number, a: number)
---@field setMapColorGrass fun(r: number, g: number, b: number, a: number)
---@field setMapColorSand fun(r: number, g: number, b: number, a: number)
---@field setMapColorSnow fun(r: number, g: number, b: number, a: number)
---@field setMapColorRock fun(r: number, g: number, b: number, a: number)
---@field setMapColorGravel fun(r: number, g: number, b: number, a: number)
---@field getWidth fun(): number
---@field getHeight fun(): number
screen = {}

---@class Map
---@field screenToMap fun(mapX: number, mapY: number, zoom: number, screenW: number, screenH: number, pixelX: number, pixelY: number): number, number
---@field mapToScreen fun(mapX: number, mapY: number, zoom: number, screenW: number, screenH: number, worldX: number, worldY: number): number, number
map = {}

---@class Http
---@field httpGet fun(port: number, path: string)
async = {}
