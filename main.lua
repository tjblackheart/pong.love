local shine = require "moonshine"
local gfx, kb, audio = love.graphics, love.keyboard, love.audio
local screenW, screenH = gfx.getWidth(), gfx.getHeight()
local isFullscreen = love.window.getFullscreen()
local running, reset = false, false
local paddle_l, paddle_r, ball = {}, {}, {}
local sounds, effects = {}, {}
local text = { t1 = "", t2 = "", alpha = 1, timer = 0 }
local maxAngle = 165

math.randomseed(os.time())

local function initObjects()
    paddle_l = {
        x = 20, y = screenH/2-50, h = 100, w = 10,
        speed = 250, score = 0
    }

    paddle_r = {
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

    sounds.paddle = audio.newSource('audio/paddle.ogg', 'static')
    sounds.ball = audio.newSource('audio/ball.ogg', 'static')
    sounds.miss = audio.newSource('audio/out.ogg', 'static')
    sounds.win = audio.newSource('audio/win.ogg', 'static')

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
        running = not running
        text.t1 = 'GAME PAUSED\n\nPress SPACE to continue'
    end

    if key == 'escape' then love.event.push('quit') end

    if key == 'f' then
        isFullscreen = not isFullscreen
        love.window.setFullscreen(isFullscreen)
    end
end

function love.update(dt)

    if running == false then
        text.timer = text.timer + dt
        if text.timer >= .5 then
            text.timer = text.timer - .5
            text.alpha = text.alpha == 1 and 0 or 1
        end
        return
    end

    if reset == true then
        initObjects()
        reset = false
    end

    -- player1 paddle movement
    if kb.isDown('up') and paddle_r.y > 0 then
        paddle_r.y = paddle_r.y - paddle_r.speed * dt
    end

    if kb.isDown('down') and paddle_r.y < screenH-paddle_r.h then
        paddle_r.y = paddle_r.y + paddle_r.speed * dt
    end

    -- player2 paddle movement
    --[[if kb.isDown('w') and paddle_l.y > 0 then
        paddle_l.y = paddle_l.y - paddle_l.speed*dt
    end
    if kb.isDown('s') and paddle_l.y < screenH-paddle_l.h then
        paddle_l.y = paddle_l.y + paddle_l.speed*dt
    end]]

    -- computer paddle movement
    if ball.hdirection == -1 then
        if round(ball.y) < round(paddle_l.y) + paddle_l.h/2 then
            paddle_l.y = round(paddle_l.y - paddle_l.speed * dt * .75) -- make the computer move somewhat slower
            if paddle_l.y < 0 then paddle_l.y = 0 end
        elseif round(ball.y) > round(paddle_l.y) + paddle_l.h/2 then
            paddle_l.y = round(paddle_l.y + paddle_l.speed * dt * .75)
            if paddle_l.y+paddle_l.h > screenH then paddle_l.y = screenH - paddle_l.h end
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
    if ball.y - ball.h <= 0 then
        ball.vdirection = 1
        audio.play(sounds.ball)
    elseif ball.y+ball.h >= screenH then
        ball.vdirection = -1
        audio.play(sounds.ball)
    end

    -- collision check
    if hit(paddle_l, ball) or hit(paddle_r, ball) then
        audio.play(sounds.paddle)
        ball.hdirection = -ball.hdirection
        ball.vdirection = math.random(2) == 1 and 1 or -1 -- randomly select 1 or -1
        ball.hspeed = ball.hspeed + 10 -- speed up
        ball.angle  = math.random(20, maxAngle) -- random vertical speed
    end

    -- ball out: score
    if ball.x > screenW or ball.x < 0 then
        audio.play(sounds.miss)

        if ball.x > screenW then paddle_l.score = paddle_l.score + 1 end
        if ball.x < 0 then paddle_r.score = paddle_r.score + 1 end

        ball.hspeed = 300
        ball.angle  = math.random(20, maxAngle)
        ball.x = screenW/2-ball.w/2
        ball.y = screenH/2-ball.h/2
        ball.vdirection = math.random(2) == 1 and 1 or -1
        ball.hdirection = math.random(2) == 1 and 1 or -1

        if paddle_l.score == 11 or paddle_r.score == 11 then
            text.t2 = 'Matchball!'
        end

        if paddle_l.score == 12 or paddle_r.score == 12 then
            audio.play(sounds.win)

            text.t2 = ''
            running = false
            reset = true

            if paddle_l.score == 12 then text.t1 = "I win!"
            elseif paddle_r.score == 12 then text.t1 = "You win!"
            end

            text.t1 = text.t1 .. "\n\nPress SPACE to restart"
        end
    end

end

function love.draw(dt)
    effects(function()
        if running == false then
            gfx.setColor(255, 255, 255, text.alpha)
            gfx.printf(text.t1, 0, screenH-80, screenW, 'center')
        end

        gfx.setColor(255, 255, 255, 1)
        if paddle_l.y < 80 then gfx.setColor(255, 255, 255, .5) end
        gfx.print('Computer', 20, 40)

        gfx.setColor(255, 255, 255, 1)
        if paddle_r.y < 80 then gfx.setColor(255, 255, 255, .5) end
        gfx.print('Player', screenW-110, 40)

        gfx.setColor(255, 255, 255, 1)
        gfx.print(paddle_l.score, screenW/2-60, 40)
        gfx.print(paddle_r.score, screenW/2+40, 40)
        gfx.printf(text.t2, 0, screenH-40, screenW, 'center')

        gfx.rectangle('fill', paddle_l.x, paddle_l.y, paddle_l.w, paddle_l.h)
        gfx.rectangle('fill', paddle_r.x, paddle_r.y, paddle_r.w, paddle_r.h)
        gfx.rectangle('fill', ball.x, ball.y, ball.w, ball.h)

        gfx.setColor(255, 255, 255, .5)
        gfx.rectangle('line', screenW/2, 0, 1, screenH)
    end)

    -- gfx.print("angle: " .. tostring(ball.vspeed), 20, screenH - 80)
    -- gfx.print("hspeed: " .. tostring(ball.hspeed), 20, screenH - 40)
end
