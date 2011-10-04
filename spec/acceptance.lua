require 'spec/lib/middleclass'

Stateful = require 'stateful'

context("Acceptance tests", function()

  local Enemy

  before(function()
    Enemy = class('Enemy'):include(Stateful)

    function Enemy:initialize(health)
      self.health = health
    end

    function Enemy:speak()
      return 'My health is ' .. tostring(self.health)
    end

  end)

  test("works on the basic case", function()

    local Immortal = Enemy:addState('Immortal')

    function Immortal:speak() return 'I am UNBREAKABLE!!' end
    function Immortal:die()   return 'I can not die now!' end

    local peter = Enemy:new(10)

    assert_equal(peter:speak(), 'My health is 10')

    peter:gotoState('Immortal')

    assert_equal(peter:speak(), 'I am UNBREAKABLE!!')
    assert_equal(peter:die(), 'I can not die now!')

    peter:gotoState(nil)

    assert_equal(peter:speak(), 'My health is 10')

  end)

  test("basic callbacks", function()

    local Drunk = Enemy:addState('Drunk')

    function Drunk:enterState() self.health = self.health - 1 end
    function Drunk:exitState() self.health = self.health + 1 end

    local john = Enemy:new(10)

    assert_equal(john:speak(), 'My health is 10')

    john:gotoState('Drunk')
    assert_equal(john:speak(), 'My health is 9')
    assert_type(john.enterState, 'nil')
    assert_type(john.exitState, 'nil')

    john:gotoState(nil)
    assert_equal(john:speak(), 'My health is 10')

  end)

  test("state inheritance", function()

    function Enemy:sing() return "every move you make" end

    local Happy = Enemy:addState('Happy')
    function Happy:speak() return "hehehe" end

    local Stalker = class('Stalker', Enemy)
    function Stalker.states.Happy:sing() return "I'll be watching you" end

    local jimmy = Stalker:new(10)

    assert_equal(jimmy:speak(), "My health is 10")
    assert_equal(jimmy:sing(), "every move you make")
    jimmy:gotoState('Happy')
    assert_equal(jimmy:sing(), "I'll be watching you")
    assert_equal(jimmy:speak(), "hehehe")

  end)

  test("state stacking", function()

    function Enemy:sing()  return "la donna e mobile" end
    function Enemy:dance() return "up down left right" end
    function Enemy:all()   return table.concat({ self:dance(), self:sing(), self:speak() }, ' - ') end

    local SteveWonder = Enemy:addState('SteveWonder')
    function SteveWonder:sing() return 'you are the sunshine of my life' end

    local FredAstaire = Enemy:addState('FredAstaire')
    function FredAstaire:dance() return 'clap clap clappity clap' end

    local PhilCollins = Enemy:addState('PhilCollins')
    function PhilCollins:dance() return "I can't dance" end
    function PhilCollins:sing() return "I can't sing" end
    function PhilCollins:speak() return "Only thing about me is the way I walk" end

    local artist = Enemy:new(10)


    assert_equal(artist:all(), "up down left right - la donna e mobile - My health is 10")

    artist:gotoState('PhilCollins')
    assert_equal(artist:all(), "I can't dance - I can't sing - Only thing about me is the way I walk")

    artist:pushState('FredAstaire')
    assert_equal(artist:all(), "clap clap clappity clap - I can't sing - Only thing about me is the way I walk")

    artist:pushState('SteveWonder')
    assert_equal(artist:all(), "clap clap clappity clap - you are the sunshine of my life - Only thing about me is the way I walk")

    artist:popAllStates()
    assert_equal(artist:all(), "up down left right - la donna e mobile - My health is 10")


    artist:pushState('PhilCollins')
    artist:pushState('FredAstaire')
    artist:pushState('SteveWonder')
    artist:popState('FredAstaire')
    assert_equal(artist:all(), "I can't dance - you are the sunshine of my life - Only thing about me is the way I walk")

    artist:popState()
    assert_equal(artist:all(), "I can't dance - I can't sing - Only thing about me is the way I walk")

    artist:popState('FredAstaire')
    assert_equal(artist:all(), "I can't dance - I can't sing - Only thing about me is the way I walk")

    artist:gotoState('FredAstaire')
    assert_equal(artist:all(), "clap clap clappity clap - la donna e mobile - My health is 10")

  end)

  test("stack-related callbacks", function()
    local TweetPaused = Enemy:addState('TweetPaused')
    function TweetPaused:pausedState() self.tweet = true end

    local TootContinued = Enemy:addState('TootContinued')
    function TootContinued:continuedState() self.toot = true end

    local PamPushed = Enemy:addState('PamPushed')
    function PamPushed:pushedState() self.pam = true end

    local PopPopped = Enemy:addState('PopPopped')
    function PopPopped:poppedState() self.pop = true end

    e = Enemy:new()

    e:gotoState('TweetPaused')
    assert_nil(e.tweet)
    e:pushState('TootContinued')
    assert_true(e.tweet)

    e:pushState('PopPopped')
    e:popState()

    assert_true(e.toot)
    assert_true(e.pop)

    e:pushState('PopPopped')
    e:pushState('PamPushed')
    assert_true(self.pam)

    e.tweet = false
    e.pop = false

    e:popState('PopPopped')
    assert_true(self.pop)

    e:popState()
    assert_true(self.tweet)


  end)

  context("Errors", function()
    test("addState raises an error if the state is already present, or not a valid id", function()
      local Immortal = Enemy:addState('Immortal')
      assert_error(function() Enemy:addState('Immortal') end)
      assert_error(function() Enemy:addState(1) end)
      assert_error(function() Enemy:addState() end)
    end)
    test("gotoState raises an error if the state doesn't exist, or not a valid id", function()
      local e = Enemy:new()
      assert_error(function() e:gotoState('Inexisting') end)
      assert_error(function() e:gotoState(1) end)
      assert_error(function() e:gotoState({}) end)
    end)
  end)

end)

