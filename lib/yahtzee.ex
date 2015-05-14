defmodule Yahtzee do
  @sides 6
  @num_dice 5

  defstruct score: [ones: nil, twos: nil, threes: nil, fours: nil, fives: nil, sixes: nil,
                    three_of_kind: nil, four_of_kind: nil, full_house: nil,
                    small_straight: nil, large_straight: nil, yahtzee: nil, bonus: 0] 

  def score_functions, do: [three_of_kind: &score_three_of_kind/1, four_of_kind: &score_four_of_kind/1,
    small_straight: &score_small_straight/1, large_straight: &score_large_straight/1, yahtzee: &score_yahtzee/1]

  def empty_dice, do: [0,0,0,0,0]
  def all_dice_pos, do: [0,1,2,3,4]

  def roll(dice \\ empty_dice, which \\ all_dice_pos) do
    # if Enum.count(dice) != @num_dice, do: raise "Incorrect number of dice!"
    Stream.iterate(0, &(&1+1)) 
    |> Stream.zip(dice) 
    |> Stream.map(
      fn {pos, die} -> 
        if pos in which do
          :random.uniform(@sides)
        else
          die
        end
      end)
    |> Enum.to_list
  end

  def score(dice) do
    top = score_top(dice)
    
  end

  def score_top(dice) do
    1 .. @sides |> Enum.map( fn x -> Enum.count(dice, &(&1 == x)) * x end )
  end

  def score_full_house(dice) do
    unique = dice |> Enum.uniq
    case unique  do
      [a, _] -> if Enum.count(dice, &(&1 == a)) in [2,3], do: 25, else: 0
      _ -> 0
    end
  end

  def score_three_of_kind(dice), do: score_n_of_kind(dice, 3)
  def score_four_of_kind(dice), do: score_n_of_kind(dice, 4)
  def score_yahtzee(dice)  do
    if score_n_of_kind(dice, 5) != 0 do
      50
    else
      0
    end
  end
  
  def score_n_of_kind(dice, n) do
    1 .. @sides |> Enum.reduce(0, 
      fn x, acc ->
        case acc do
          0 -> c = Enum.count(dice, &(&1 == x))
               if c >= n, do: Enum.sum(dice), else: 0
          _ -> acc
        end
      end)
  end

  def score_small_straight(dice), do: (if score_straight(dice, 4), do: 30, else: 0)
  def score_large_straight(dice), do: (if score_straight(dice, 5), do: 40, else: 0)

  def score_straight(dice, length) do
    # normalize dice values to start at 1
    min = Enum.min(dice)
    dice2 = dice |> Enum.map(&(&1 - min + 1))
    1 .. length |> Enum.map(&(&1 in dice2)) |> Enum.all?
  end

  def test() do
    IO.puts "Test!"
    roll([1,2,3,4,5], [1,2,3])
  end
end
