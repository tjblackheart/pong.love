local shine = require "moonshine"
local gfx, kb, sfx = love.graphics, love.keyboard, love.audio
local screenW, screenH = gfx.getWidth(), gfx.getHeight()
local isFullscreen, isRunning, isGameOver = love.window.getFullscreen(), false, false
local left, right, ball = {}, {}, {}
local sounds, effects = {}, {}
local text = { t1 = "", t2 = "", alpha = 1, timer = 0 }
local maxAngle = 165

local function initObjects()
    left = {
        x = 20, y = screenH/2-50, h = 100, w = 10,
        speed = 250, score = 0
    }

    right = {
        x = screenW-30, y = screenH/2-50, h = 100, w = 10,
        speed = 250, score = 0
    }

    ball = {
        x = screenW/2-5, y = screenH/2-5, h = 10, w = 10,
        hspeed = 300, angle = math.random(20, maxAngle),
        hdirection = 1, vdirection = 1
    }
end

local function hit(a, b)
    return
        a.x <= b.x + b.w and
        b.x <= a.x + a.w and
        a.y <= b.y + b.h and
        b.y <= a.y + a.h
end

local function round(x)
    return (x >= 0 and math.floor(x + 0.5)) or math.ceil(x - 0.5)
end

function love.load()
    love.mouse.setVisible(false)
    math.randomseed(os.time())
    initObjects()

    text.t1 = "Welcome to PONG\n\nPress SPACE to start"

    sounds.paddle = sfx.newSource('audio/paddle.ogg', 'static')
    sounds.ball = sfx.newSource('audio/ball.ogg', 'static')
    sounds.miss = sfx.newSource('audio/out.ogg', 'static')
    sounds.win = sfx.newSource('audio/win.ogg', 'static')

    gfx.setFont(gfx.newFont('font/digital-7.ttf', 32))
    gfx.setBackgroundColor(0, 0, 0)

    -- fx
    local grain = shine.effects.filmgrain()
    local blur = shine.effects.fastgaussianblur()
    local glow = shine.effects.glow()
    local scanlines = shine.effects.scanlines()

    effects = shine.chain(glow).chain(blur).chain(scanlines).chain(grain)
    effects.params = {
        glow = { strength = 20 },
        scanlines = { width = 1, opacity = .5 },
        filmgrain = { opacity = .75 }
    }
end

function love.keypressed(key)
    if key == 'space' then
        isRunning = not isRunning
        text.t1 = 'GAME PAUSED\n\nPress SPACE to continue'
    end

    if key == 'escape' then love.event.push('quit') end

    if key == 'f' then
        isFullscreen = not isFullscreen
        love.window.setFullscreen(isFullscreen)
    end
end

function love.update(dt)

    if isRunning == false then
        text.timer = text.timer + dt
        if text.timer >= .5 then
            text.timer = text.timer - .5
            text.alpha = text.alpha == 1 and 0 or 1
        end
        return
    end

    if isGameOver == true then
        initObjects()
        isGameOver = false
    end

    -- player1 paddle movement
    if kb.isDown('up') and right.y > 0 then
        right.y = right.y - right.speed * dt
    end

    if kb.isDown('down') and right.y < screenH-right.h then
        right.y = right.y + right.speed * dt
    end

    -- player2 paddle movement
    --[[if kb.isDown('w') and left.y > 0 then
        left.y = left.y - left.speed*dt
    end
    if kb.isDown('s') and left.y < screenH-left.h then
        left.y = left.y + left.speed*dt
    end]]

    -- computer paddle movement
    if ball.hdirection == -1 then
        if round(ball.y) < round(left.y) + left.h/2 then
            left.y = round(left.y - left.speed * dt * .75) -- make the computer move somewhat slower
            if left.y < 0 then left.y = 0 end
        elseif round(ball.y) > round(left.y) + left.h/2 then
            left.y = round(left.y + left.speed * dt * .75)
            if left.y + left.h > screenH then left.y = screenH - left.h end
        end
    end

    -- ball positions
    if ball.hdirection == 1 then ball.x = ball.x + ball.hspeed * dt
    else ball.x = ball.x - ball.hspeed * dt
    end

    if ball.vdirection == 1 then ball.y = ball.y + ball.angle * dt
    else ball.y = ball.y - ball.angle * dt
    end

    -- ball hits edges
    if ball.y <= 0 then
        sfx.play(sounds.ball)
        ball.vdirection = 1
    elseif ball.y + ball.h >= screenH then
        sfx.play(sounds.ball)
        ball.vdirection = -1
    end

    -- collision check
    if hit(left, ball) or hit(right, ball) then
        sfx.play(sounds.paddle)

        -- double check positions
        if ball.x < left.x+left.w then ball.x = left.x + left.w end
        if ball.x + ball.w > right.x then ball.x = right.x - ball.w end

        ball.hdirection = -ball.hdirection
        ball.vdirection = math.random(2) == 1 and 1 or -1 -- randomly select 1 or -1
        ball.hspeed = ball.hspeed + 10 -- speed up
        ball.angle  = math.random(20, maxAngle) -- random vertical speed
    end

    -- ball out: score
    if ball.x > screenW or ball.x < 0 then
        sfx.play(sounds.miss)

        if ball.x > screenW then left.score = left.score + 1 end
        if ball.x < 0 then right.score = right.score + 1 end

        ball.hspeed = 300
        ball.angle  = math.random(20, maxAngle)
        ball.x = screenW/2-ball.w/2
        ball.y = screenH/2-ball.h/2
        ball.vdirection = math.random(2) == 1 and 1 or -1
        ball.hdirection = math.random(2) == 1 and 1 or -1

        if left.score == 11 or right.score == 11 then
            text.t2 = 'Matchball!'
        end

        if left.score == 12 or right.score == 12 then
            sfx.play(sounds.win)

            text.t2 = ''
            isRunning = false
            isGameOver = true

            if left.score == 12 then text.t1 = "I win!"
            elseif right.score == 12 then text.t1 = "You win!"
            end

            text.t1 = text.t1 .. "\n\nPress SPACE to restart"
        end
    end

end

function love.draw(dt)
    effects(function()
        if isRunning == false then
            gfx.setColor(255, 255, 255, text.alpha)
            gfx.printf(text.t1, 0, screenH-80, screenW, 'center')
        end

        gfx.setColor(255, 255, 255, 1)
        if left.y < 80 then gfx.setColor(255, 255, 255, .5) end
        gfx.print('Computer', 20, 40)

        gfx.setColor(255, 255, 255, 1)
        if right.y < 80 then gfx.setColor(255, 255, 255, .5) end
        gfx.print('Player', screenW-110, 40)

        gfx.setColor(255, 255, 255, 1)
        gfx.print(left.score, screenW/2-60, 40)
        gfx.print(right.score, screenW/2+40, 40)
        gfx.printf(text.t2, 0, screenH-40, screenW, 'center')

        gfx.rectangle('fill', left.x, left.y, left.w, left.h)
        gfx.rectangle('fill', right.x, right.y, right.w, right.h)
        gfx.rectangle('fill', ball.x, ball.y, ball.w, ball.h)

        gfx.setColor(255, 255, 255, .5)
        gfx.rectangle('line', screenW/2, 0, 1, screenH)
    end)

    -- gfx.print("angle: " .. tostring(ball.angle), 20, screenH - 80)
    -- gfx.print("hspeed: " .. tostring(ball.hspeed), 20, screenH - 40)
end

function love.focus(f)
    if not f and isRunning then isRunning = not isRunning end
end
