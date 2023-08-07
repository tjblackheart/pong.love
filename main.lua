local shine = require 'moonshine'
local gfx = love.graphics
local kb = love.keyboard
local screenW, screenH = gfx.getWidth(), gfx.getHeight()
local isFullscreen = love.window.getFullscreen()
local running = false
local paddle_l, paddle_r, ball = {}, {}, {}
local text = {
    t1 = "Welcome to PONG\n\nPress SPACE to start",
    t2 = '',
    alpha = 1,
    timer = 0
}

math.randomseed(os.time())

function initObjects()
    paddle_l = {
        x = 20,
        y = screenH/2-50,
        height = 100,
        width = 10,
        speed = 250,
        score = 0
    }

    paddle_r = {
        x = screenW-30,
        y = screenH/2-50,
        height = 100,
        width = 10,
        speed = 250,
        score = 0
    }

    ball = {
        x = screenW/2-5,
        y = screenH/2-5,
        speed = 300,
        angle = math.random(20, 180),
        hdirection = 1,
        vdirection = 1,
        height = 10,
        width = 10
    }
end

function love.load()
    math.randomseed(os.time())

    font = gfx.newFont('font/digital-7.ttf', 32);
    paddleblip = love.audio.newSource('audio/paddle.ogg', 'static')
    ballblip = love.audio.newSource('audio/ball.ogg', 'static')
    ballout = love.audio.newSource('audio/out.ogg', 'static')
    win = love.audio.newSource('audio/win.ogg', 'static')

    gfx.setFont(font);
    love.mouse.setVisible(false)
    initObjects()

    -- fx
    grain = shine.effects.filmgrain()
    blur = shine.effects.fastgaussianblur()
    glow = shine.effects.glow()
    scanlines = shine.effects.scanlines()
    effect = shine.chain(glow).chain(blur).chain(scanlines).chain(grain)
    effect.params = {
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
        paddle_r.y = paddle_r.y - paddle_r.speed*dt
    end

    if kb.isDown('down') and paddle_r.y < screenH-paddle_r.height then
        paddle_r.y = paddle_r.y + paddle_r.speed*dt
    end

    -- player2 paddle movement
    --[[if kb.isDown('w') and paddle_l.y > 0 then
        paddle_l.y = paddle_l.y - paddle_l.speed*dt
    end
    if kb.isDown('s') and paddle_l.y < screenH-paddle_l.height then
        paddle_l.y = paddle_l.y + paddle_l.speed*dt
    end]]

    -- computer paddle movement
    if ball.hdirection == -1 then
        if round(ball.y) < round(paddle_l.y) + paddle_l.height/2 then
            paddle_l.y = round(paddle_l.y - paddle_l.speed * dt * .75) -- make the computer move somewhat slower
            if paddle_l.y < 0 then paddle_l.y = 0 end
        elseif round(ball.y) > round(paddle_l.y) + paddle_l.height/2 then
            paddle_l.y = round(paddle_l.y + paddle_l.speed * dt * .75)
            if paddle_l.y+paddle_l.height > screenH then paddle_l.y = screenH - paddle_l.height end
        end
    end

    -- ball positions
    if ball.hdirection == 1 then ball.x = ball.x + ball.speed*dt
    else ball.x = ball.x - ball.speed*dt
    end

    if ball.vdirection == 1 then ball.y = ball.y + ball.angle*dt
    else ball.y = ball.y - ball.angle*dt
    end

    -- ball hits edges
    if ball.y - ball.height <= 0 then
        ball.vdirection = 1
        love.audio.play(ballblip)
    elseif ball.y+ball.height >= screenH then
        ball.vdirection = -1
        love.audio.play(ballblip)
    end

    -- ball hits paddles
    -- changed paddle.width to 1 to prevent "ball gets stuck in the fucking paddle" thingy
    if
    collision(paddle_l.x+paddle_l.width, paddle_l.y, 1, paddle_l.height, ball.x, ball.y, ball.width, ball.height) or
    collision(paddle_r.x, paddle_r.y, 1, paddle_r.height, ball.x, ball.y, ball.width, ball.height) then
        ball.hdirection = -ball.hdirection
        ball.vdirection = math.random(2) == 1 and 1 or -1 -- randomly select 1 or -1
        ball.speed = ball.speed + 10 -- speed up
        ball.angle  = math.random(20, 180) -- random vertical speed
        love.audio.play(paddleblip)
    end

    -- ball out: score
    if ball.x > screenW or ball.x < 0 then
        if ball.x > screenW then paddle_l.score = paddle_l.score + 1 end
        if ball.x < 0 then paddle_r.score = paddle_r.score + 1 end

        love.audio.play(ballout)
        ball.speed = 300
        ball.angle  = math.random(20, 180)
        ball.x = screenW/2-ball.width/2
        ball.y = screenH/2-ball.height/2
        ball.vdirection = math.random(2) == 1 and 1 or -1
        ball.hdirection = math.random(2) == 1 and 1 or -1

        if paddle_l.score == 11 or paddle_r.score == 11 then text.t2 = 'Matchball!' end
        if paddle_l.score == 12 or paddle_r.score == 12 then
            text.t2 = ''
            running = false
            reset = true
            love.audio.play(win)

            if paddle_l.score == 12 then text.t1 = "I win!"
            elseif paddle_r.score == 12 then text.t1 = "You win!"
            end

            text.t1 = text.t1 .. "\n\nPress SPACE to restart"
        end
    end

end

function love.draw(dt)
    effect(function()
        gfx.setBackgroundColor(0, 0, 0)

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

        gfx.rectangle('fill', paddle_l.x, paddle_l.y, paddle_l.width, paddle_l.height)
        gfx.rectangle('fill', paddle_r.x, paddle_r.y, paddle_r.width, paddle_r.height)
        gfx.rectangle('fill', ball.x, ball.y, ball.width, ball.height)

        gfx.setColor(255, 255, 255, .5)
        gfx.rectangle('line', screenW/2, 0, 1, screenH)
    end)

    --gfx.print( love.timer.getFPS(), 20, screenH-40 )
end

function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2+w2 and
        x2 < x1+w1 and
        y1 < y2+h2 and
        y2 < y1+h1
end

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
