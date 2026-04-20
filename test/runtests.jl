using Test, ToggleableAsserts

function foo(u, v)
    @toggled_assert length(u) == length(v)
    1
end

@testset "boolean toggled asserts" begin
    @test_throws AssertionError foo([1, 2], [1])
    @test_throws AssertionError("3 is an odd number!") @toggled_assert iseven(3) "3 is an odd number!"

    toggle(false)
    @test foo([1, 2], [1]) == 1

    toggle(true)
    @test_throws AssertionError foo([1, 2], [1])
end

@testset "debug levels" begin
    # disabled: no assertions should fire
    toggle(0)
    @test begin
        @dassert 1 false
        @dassert 100 false
        true
    end

    # level 1 enabled: level 1 should fire, level 2 should not
    toggle(1)
    @test_throws AssertionError @dassert 1 false
    @test begin
        @dassert 2 false
        true
    end

    # level 2 enabled: level 1 and 2 should fire
    toggle(2)
    @test_throws AssertionError @dassert 2 false
    @test_throws AssertionError @dassert 1 false

    # message propagation
    toggle(2)
    @test_throws AssertionError("bad level") @dassert 2 false "bad level"

    # boolean toggles: false disables, true enables
    toggle(false)
    @test begin
        @dassert 1 false
        true
    end

    toggle(true)
    @test_throws AssertionError @dassert 1 false

    # higher numeric level enables lower levels
    toggle(5)
    @test_throws AssertionError @dassert 1 false

    # macro levels <= 0 are ignored regardless of global setting
    toggle(5)
    @test begin
        @dassert 0 false
        @dassert -1 false
        true
    end
end

Threads.@threads for i in 1:20
    rand(Bool) ? toggle(true) : toggle(false)
end
