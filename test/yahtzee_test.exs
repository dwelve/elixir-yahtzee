defmodule YahtzeeTest do
  use ExUnit.Case

  def assert_score(func, dice, expected) do
    assert func.(dice) == expected
  end

  def assert_score_func(func) do
    # is there a better way to curry functions?
    fn dice, expected -> assert_score(func, dice, expected) end
  end

  test "upper score calculation is correct" do
    assert Yahtzee.score_top_n([1,2,3,4,5], 1) == 1
    assert Yahtzee.score_top_n([1,1,3,4,5], 1) == 2
    assert Yahtzee.score_top_n([1,1,1,4,5], 1) == 3
    assert Yahtzee.score_top_n([1,1,1,1,5], 1) == 4
    assert Yahtzee.score_top_n([1,1,1,1,1], 1) == 5
    assert Yahtzee.score_top_n([6,6,6,2,3], 6) == 18
    assert Yahtzee.score_top_n([6,6,6,2,3], 4) == 0
  end

  test "chance score is correct" do
    assert Yahtzee.score_chance([1,2,3,4,5]) == 15
    assert Yahtzee.score_chance([5,5,5,5,5]) == 25
  end

  test "full house score is correct" do
    assert Yahtzee.score_full_house([1,1,1,2,2]) == 25
    assert Yahtzee.score_full_house([1,1,2,2,2]) == 25
    assert Yahtzee.score_full_house([1,2,2,2,1]) == 25
    assert Yahtzee.score_full_house([1,2,2,2,2]) == 0
    assert Yahtzee.score_full_house([2,2,2,2,2]) == 0
    assert Yahtzee.score_full_house([1,1,2,2,3]) == 0
  end

  test "three of kind score is correct" do
    assert Yahtzee.score_three_of_kind([1,1,1,5,5]) == 13
    assert Yahtzee.score_three_of_kind([1,1,1,1,5]) == 9
    assert Yahtzee.score_three_of_kind([1,1,2,5,5]) == 0
  end

  test "four of kind score is correct" do
    assert Yahtzee.score_four_of_kind([1,1,1,1,5]) == 9
    assert Yahtzee.score_four_of_kind([1,1,1,5,5]) == 0
  end

  test "yahtzee score is correct" do
    assert Yahtzee.score_yahtzee([1,1,1,1,1]) == 50
    assert Yahtzee.score_yahtzee([3,3,3,3,3]) == 50
    assert Yahtzee.score_yahtzee([1,1,1,1,3]) == 0
  end

  test "small straight score is correct" do
    f = assert_score_func(&Yahtzee.score_small_straight/1)
    f.([1,2,3,4,5], 30)
    f.([1,2,3,4,1], 30)
    f.([4,3,2,1,1], 30)
    f.([1,4,3,2,1], 30)
    f.([6,5,4,1,3], 30)
    f.([6,5,2,1,3], 0)
    f.([1,5,4,1,3], 0)
  end

  test "large straight score is correct" do
    f = assert_score_func(&Yahtzee.score_large_straight/1)
    f.([1,2,5,4,3], 40)
    f.([6,5,3,2,4], 40)
    f.([4,3,2,1,1], 0)
    f.([1,4,3,2,1], 0)
    f.([6,5,4,1,3], 0)
    f.([6,5,2,1,3], 0)
    f.([1,5,4,1,3], 0)
  end

end
