defmodule Yahtzee do
  @sides 6
  @num_dice 5

  defstruct score: [ones: nil, twos: nil, threes: nil, fours: nil, fives: nil, sixes: nil,
                    three_of_kind: nil, four_of_kind: nil, full_house: nil,
                    small_straight: nil, large_straight: nil, yahtzee: nil, bonus: 0]

  def score_functions, do: [
    ones: &(score_top_n(&1, 1)),
    twos: &(score_top_n(&1, 2)),
    threes: &(score_top_n(&1, 3)),
    fours: &(score_top_n(&1, 4)),
    fives: &(score_top_n(&1, 5)),
    sixes: &(score_top_n(&1, 6)),
    three_of_kind: &score_three_of_kind/1, four_of_kind: &score_four_of_kind/1,
    full_house: &score_full_house/1, small_straight: &score_small_straight/1,
    large_straight: &score_large_straight/1, yahtzee: &score_yahtzee/1]

  def max_scores do
    [ ones: 1*@num_dice,
      twos: 2*@num_dice,
      threes: 3*@num_dice,
      fours: 4*@num_dice,
      fives: 5*@num_dice,
      sixes: 6*@num_dice,
      three_of_kind: 6*@num_dice,
      four_of_kind: 6*@num_dice,
      full_house: 25,
      small_straight: 30,
      large_straight: 40,
      yahtzee: 50 ] 
  end

  def empty_dice, do: Stream.cycle([0]) |> Enum.take(@num_dice)
  def all_dice_pos, do: 0 .. (@num_dice-1) |> Enum.to_list

  def start_game() do
    game_loop(empty_dice, 3, %Yahtzee{})
  end

  def game_loop(dice, rolls_left, game=%Yahtzee{}) do
    print_game(dice, rolls_left, game)
    hand_score = score(dice)
    case rolls_left do
      3 -> game_loop(roll(), 2, game)
      2 -> print_hand_score(hand_score)
           game_loop(ask_which(dice), 1, game)
      1 -> print_hand_score(hand_score)
           game_loop(ask_which(dice), 0, game)
      0 -> print_hand_score(hand_score)
           dice
    end
  end

  def print_game(dice, rolls_left, game=%Yahtzee{}) do
    IO.puts "\n == Yahtzee Game == "
    IO.puts inspect(game)
    IO.puts "Rolls left: #{rolls_left}"
    IO.puts "Dice: #{inspect dice}"
  end

  def print_hand_score(s) do
    IO.puts inspect(s)
  end

  def ask_which(dice) do
    IO.puts "Dice are #{inspect dice}"
    which = IO.gets "Roll which ones? "
    which = which
           |> String.split(~r/[\D]+/, trim: true)
           |> Enum.map(&String.to_integer/1)
           |> Enum.filter(&(&1 in all_dice_pos))
           |> Enum.uniq
    roll(dice, which)
  end

  def roll(dice \\ empty_dice, which \\ all_dice_pos) do
    # if Enum.count(dice) != @num_dice, do: raise "Incorrect number of dice!"
    Stream.with_index(dice) 
    |> Stream.map(
      fn {die, pos} -> 
        if pos in which do
          :random.uniform(@sides)
        else
          die
        end
      end)
    |> Enum.to_list
  end

  def score(dice) do
    for {name, func} <- score_functions do
      {name, func.(dice)}
    end
  end

  def score(dice, game = %Yahtzee{}) do
    scores = score(dice)
    if (scores[:yahtzee] != 0) and (game[:bonus] != 0) do
      game = Dict.put(game, :bonus, game[:bonus] + 100)
    end
    scores
  end

  def score_top_n(dice, n), do: Enum.count(dice, &(&1 == n)) * n

  def score_full_house(dice) do
    unique = dice |> Enum.uniq
    case unique  do
      [a, _] -> if Enum.count(dice, &(&1 == a)) in [2,3], do: max_scores[:full_house], else: 0
      _ -> 0
    end
  end

  def score_three_of_kind(dice), do: score_n_of_kind(dice, 3)
  def score_four_of_kind(dice), do: score_n_of_kind(dice, 4)
  def score_yahtzee(dice), do: (if score_n_of_kind(dice, 5) != 0, do: max_scores[:yahtzee], else: 0)
  
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

  def score_small_straight(dice), do: (if score_straight(dice, 4), do: max_scores[:small_straight], else: 0)
  def score_large_straight(dice), do: (if score_straight(dice, 5), do: max_scores[:large_straight], else: 0)

  def score_straight(dice, length) do
    # normalize dice values to start at 1
    min = Enum.min(dice)
    dice2 = dice |> Enum.map(&(&1 - min + 1))
    1 .. length |> Enum.map(&(&1 in dice2)) |> Enum.all?
  end

end
