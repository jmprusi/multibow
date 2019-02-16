--[[
Copyright 2019 Harald Albrecht

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

require "mocked-keybow"
local mb = require("snippets/multibow")

describe("multibow keys", function()

    local tap = spy.on(keybow, "tap_key")
    local mod = spy.on(keybow, "set_modifier")

    before_each(function()
        tap:clear()
        mod:clear()
    end)

    it("taps a plain honest key", function()
        mb.tap("x")
        assert.spy(tap).was.called(1)
        assert.spy(tap).was.called_with("x")
        assert.spy(mod).was_not.called()
    end)

    it("taps a plain honest key", function()
        mb.tap("x", keybow.LEFT_CTRL, keybow.LEFT_SHIFT)
        assert.spy(tap).was.called(1)
        assert.spy(mod).was.called(4)
        for _, ud in pairs({keybow.KEY_DOWN, keybow.KEY_UP}) do
            assert.spy(mod).was.called_with(keybow.LEFT_CTRL, ud)
            assert.spy(mod).was.called_with(keybow.LEFT_SHIFT, ud)
        end
    end)

    it("taps the same key repeatedly", function()
        mb.tap_times("x", 3)
        assert.spy(tap).was.called(3)
        assert.spy(tap).was.called_with("x")
    end)

    it("taps the same key repeatedly with modifiers", function()
        mb.tap_times("x", 3, keybow.LEFT_CTRL)
        assert.spy(tap).was.called(3)
        assert.spy(tap).was.called_with("x")
        assert.spy(mod).was.called(2)
        for _, ud in pairs({keybow.KEY_DOWN, keybow.KEY_UP}) do
            assert.spy(mod).was.called_with(keybow.LEFT_CTRL, ud)
        end
    end)

end)

describe("asynchronous keys", function()

    local tt = require("spec/snippets/ticktock")

    it("map a function on a ticking element sequence", function()
        local s = stub.new()
        local tm1 = mb.TickMapper:new(s, 1, 2, 3)
        local t = stub.new()
        local tm2 = mb.TickMapper:new(t, 42)

        mb.addkeyticker(tm1, 20)
        mb.addkeyticker(tm2, 100)

        -- "empty tick", as the tick mapper is yet delayed...
        tt.ticktock(10)
        assert.stub(s).was.Not.called()

        -- should process all elements of tm1, but none of tm2...
        tt.ticktock(30)
        assert.stub(s).was.called(3)
        assert.stub(s).was.called.With(1)
        assert.stub(s).was.called.With(2)
        assert.stub(s).was.called.With(3)
        s:clear()
        tt.ticktock(20)
        assert.stub(s).was.called(0)
        assert.stub(t).was.Not.called()

        -- should now process all elements of tm2, too.
        tt.ticktock(100)
        assert.stub(s).was.Not.called()
        assert.stub(t).was.called(1)
        assert.stub(t).was.called.With(42)
    end)

    it("tick modifiers", function()
        local s = spy.on(keybow, "set_modifier")
        mb.addmodifiers(0, keybow.KEY_DOWN, keybow.LEFT_CTRL, keybow.LEFT_SHIFT)

        tt.ticktock(50)
        assert.spy(s).was.called(2)
        assert.spy(s).was.called.With(keybow.LEFT_CTRL, keybow.KEY_DOWN)
        assert.spy(s).was.called.With(keybow.LEFT_SHIFT, keybow.KEY_DOWN)
    end)

    it("ticks keys", function()
        local sm = spy.on(keybow, "set_modifier")
        local sk = spy.on(keybow, "tap_key")
        mb.addkeys(0, "abc", keybow.LEFT_CTRL, keybow.LEFT_SHIFT)

        tt.ticktock(100)
        -- note that the modifiers were pressed AND released by now...
        assert.spy(sm).was.called(4)
        assert.spy(sm).was.called.With(keybow.LEFT_CTRL, keybow.KEY_DOWN)
        assert.spy(sm).was.called.With(keybow.LEFT_SHIFT, keybow.KEY_DOWN)
        assert.spy(sm).was.called.With(keybow.LEFT_CTRL, keybow.KEY_UP)
        assert.spy(sm).was.called.With(keybow.LEFT_SHIFT, keybow.KEY_UP)

        assert.spy(sk).was.called(3)
        assert.spy(sk).was.called.With("a")
        assert.spy(sk).was.called.With("b")
        assert.spy(sk).was.called.With("c")
    end)

end)
