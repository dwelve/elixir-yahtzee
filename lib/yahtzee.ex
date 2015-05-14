defmodule Yahtzee do
  @sides 6
  @num_dice 5
  
  # todo: just define a score struct in it's own module?
  defstruct score: [ones: :open, twos: :open, threes: :open, fours: :open, fives: :open, sixes: :open,
                    three_of_kind: :open, four_of_kind: :open, full_house: :open,
                    small_straight: :open, large_straight: :open, yahtzee: :open,
                    chance: :open, upper_bonus: 0, yahtzee_bonus: 0]

  def score_functions, do: [
    ones: &(score_top_n(&1, 1)),
    twos: &(score_top_n(&1, 2)),
    threes: &(score_top_n(&1, 3)),
    fours: &(score_top_n(&1, 4)),
    fives: &(score_top_n(&1, 5)),
    sixes: &(score_top_n(&1, 6)),
    three_of_kind: &score_three_of_kind/1,
    four_of_kind: &score_four_of_kind/1,
    full_house: &score_full_house/1,
    small_straight: &score_small_straight/1,
    large_straight: &score_large_straight/1,
    yahtzee: &score_yahtzee/1,
    chance: &score_chance/1
  ]

  def valid_score_categories, do: Keyword.keys(score_functions)

  def max_scores do
    # todo:: get rid of everything but full_house, straights, and yahtzee... 
    # and change name to fixed_scores...
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
      yahtzee: 50,
      chance: 6*@num_dice
    ] 
  end

  def empty_dice, do: Stream.cycle([0]) |> Enum.take(@num_dice)
  def all_dice_pos, do: 0 .. (@num_dice-1) |> Enum.to_list

  def start_game() do
    game_loop(empty_dice, 3, %Yahtzee{})
  end

  def game_loop(dice, rolls_left, game=%Yahtzee{}) do
    print_game(dice, rolls_left, game)
    if check_end_of_game(game) do
      IO.puts "End of game!"
    else
      hand_score = score(dice, game)
      case rolls_left do
        3 -> game_loop(roll(), 2, game)
        2 -> print_hand_score(hand_score)
             game_loop(ask_which(dice), 1, game)
        1 -> print_hand_score(hand_score)
             game_loop(ask_which(dice), 0, game)
        0 -> print_hand_score(hand_score)
             game = pick_score(hand_score, game)
             game_loop(empty_dice, 3, game)
      end
    end
  end

  def negate(x), do: !x
  def check_end_of_game(game = %Yahtzee{}) do
    # if nil is present as score value, that scoring option has not been played yet
    Map.get(game, :score) |> Keyword.values |> Enum.any?(&(&1 == :open)) |> negate
  end

  def pick_score(hand_score, game) do
    game_score = Map.get(game, :score)
    category = IO.gets "Pick a scoring category to play: "
    category = String.strip(category) |> String.to_atom

    #if !Keyword.has_key?(game_score, category) do
    if !(category in valid_score_categories) do
      IO.puts "Invalid category: #{category}"
      pick_score(hand_score, game)
    else
      if Keyword.get(game_score, category) == :open do
        new_score = Keyword.get(hand_score, category)
        # note: use Keyword.update to keep ordering, instead of Keyword.put
        updated_game_score = Keyword.put(game_score, category, new_score) |> score_upper_bonus
        %{game | score: updated_game_score}
      else
        IO.puts("Category #{category} already played")
        pick_score(hand_score, game)
      end
    end
  end

  def upper_score_categories, do: [:ones, :twos, :threes, :fours, :fives, :sixes]
  def score_upper_bonus(game_score) do
    upper_bonus = Keyword.take(game_score, upper_score_categories) |> sum_integer_values 
    case upper_bonus >= 63 do
      true  -> Keyword.put(game_score, :upper_bonus, 35)
      false -> game_score
    end
  end

  def print_game(dice, rolls_left, game=%Yahtzee{}) do
    IO.puts "\n == Yahtzee Game == "
    IO.puts inspect(game)
    IO.puts "Total score: #{get_total_score(game)}" 
    IO.puts "Rolls left: #{rolls_left}"
    IO.puts "Dice: #{inspect dice}"
  end
  
  def sum_integer_values(kw) do
    kw |> Enum.reduce(0, fn {_key, val}, acc -> if is_integer(val), do: acc+val, else: acc end)
  end
  def get_total_score(game = %Yahtzee{}) do
    game_score = Map.get(game, :score)
    #game_score |> Enum.reduce(0, fn {_key, val}, acc -> if is_integer(val), do: acc+val, else: acc end)
    game_score |> sum_integer_values
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
    # insert special rules for yahtzee
    scores
  end

  def score_chance(dice), do: Enum.sum(dice)

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

  def score_small_straight(dice), do: (if score_straight(dice, small_straights), do: max_scores[:small_straight], else: 0)
  def score_large_straight(dice), do: (if score_straight(dice, large_straights), do: max_scores[:large_straight], else: 0)

  def small_straights, do: [[1,2,3,4],[2,3,4,5],[3,4,5,6]]
  def large_straights, do: [[1,2,3,4,5], [2,3,4,5,6]] 
  def score_straight(dice, straights) do
    checks = for ss <- straights do
      Enum.map(ss, &(&1 in dice)) |> Enum.all?
    end
    Enum.any?(checks)
  end

end
