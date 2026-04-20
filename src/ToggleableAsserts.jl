module ToggleableAsserts

export @dassert, @toggled_assert, toggle

"""
    assertionlevel() -> Int

Return the active debug level used by the assertion macros.
"""
assertionlevel() = typemax(Int)

const toggle_lock = ReentrantLock()

"""
    @dassert level cond [text]

Assert `cond` when the active debug level is at least `level`.
"""
macro dassert(level, cond, text=nothing)
    assert_stmt = if text === nothing
        esc(:(@assert $cond))
    else
        esc(:(@assert $cond $text))
    end

    return :(let _level = $(esc(level))
        if _level > 0 && ToggleableAsserts.assertionlevel() >= _level
            $assert_stmt
        else
            nothing
        end
    end)
end

"""
    @toggled_assert cond [text]

Compatibility alias for `@dassert 1`.
"""
macro toggled_assert(cond, text=nothing)
    return esc(:(@dassert 1 $cond $text))
end

"""
    assert_toggle() -> Bool

Return whether assertions are currently enabled.
"""
assert_toggle() = assertionlevel() > 0

"""
    toggle(level::Int) -> Nothing

Set the active debug level for `@dassert`.
"""
function toggle(level::Int)
    lock(toggle_lock) do
        assertionlevel() == level && return nothing
        Base.delete_method(which(assertionlevel, Tuple{}))
        @eval ToggleableAsserts assertionlevel() = $level
        @info "Toggleable asserts debug level set to $level."
    end
    return nothing
end

"""
    toggle(enable::Bool) -> Nothing

Enable or disable assertions using the legacy boolean API.
"""
function toggle(enable::Bool)::Nothing
    lock(toggle_lock) do
        toggle(enable ? typemax(Int) : 0)
        on_or_off = enable ? "on." : "off."
        @info "Toggleable asserts turned " * on_or_off
    end
end

end # module
