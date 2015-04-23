class BlackJack
  attr_accessor :stage, :deck
  MAXIMUM_PLAYERS = 3

  def initialize(stage)
    @stage = stage
  end

  def play
    loop do
      system "clear"
      dealer.say "Welcome to the Great Casino!"
      set_players

      begin
        start_a_round
      end until players.empty?

      dealer.say "All players are gone."
      dealer.say "Do you want to start a new table? (y/n)"
      if gets.chomp.downcase == 'y'
        reset_table!
      else
        break
      end
    end
  end

  private

  def draw_table(hide_first_dealer_card = true)
    system "clear"
    puts "  Dealer"
    if hide_first_dealer_card
      puts "  hands: #{dealer.show_hand(true)}"
    else
      puts "  hands: #{dealer.show_hand(false)}  Total: #{dealer.total_points}"
    end
    puts 
    players.each do |player|
      puts "  ----------------------"
      puts "  Name: #{player.name}"
      puts "  Money: $#{player.money}  Bet: $#{player.bets}"
      puts
      puts "  Hands: #{player.show_hand}  Total: #{player.total_points}"
      puts
    end
  end

  def start_a_round
    system "clear"
    dealer.say "Let the round start!"

    clear_hands
    ask_for_bets
    players.reject!{ |player| player.leaving }

    if players.any?
      2.times do
        dealer.add_a_card(deck.deal_a_card)
        players.each{ |player| player.add_a_card(deck.deal_a_card)}
      end

      draw_table

      if dealer.blackjack?
        draw_table(false)
        dealer.say "The dealer has black jack!"
      else
        players.each do |player|
          take_turn(player)
        end

        # dealer's turn
        if players.reject{ |player| player.busted? }.empty?
          draw_table(false)
          dealer.say "Everyone is busted! Well done, let's go to next round."
        else
          take_turn(dealer)
        end 
      end # if someone_has_blackjack
      round_result
    end # if players.any?
  end

  def take_turn(player)
    hide_first_card = (player.is_a?(Dealer) ? false : true)
    loop do
      draw_table(hide_first_card)
      choice = player.hit_or_stand
      if choice == 'h'
        player.add_a_card(deck.deal_a_card)
        draw_table(hide_first_card)
        if player.busted?
          if player.is_a?(Dealer)
            dealer.say "Oh no! I'm busted!!"
          else
            dealer.say "You are busted!"
          end
          pause
          break
        end
      else # choice == 's'
        break 
      end
    end
  end

  
  def round_result
    draw_table(false)
    if dealer.blackjack?
      players.each do |player|
        player.blackjack? ? player.push : player.lose
      end

    else
      players.reject do |player|
        if player.busted? 
          player.lose
          true
        else
          false
        end
      end.each do |player|
        if dealer.busted?
          player.win
        else
          case dealer.total_points <=> player.total_points
          when 1 then player.lose
          when 0 then player.push
          when -1 then player.win
          end
        end
      end # player.each
    end # if dealer.blackjack?

    players.reject! do |player|
      bankrupt = (player.money == 0)
      dealer.say "Sorry, #{player.name}. You don't have money anymore. Get out of here!" if bankrupt
      bankrupt
    end

    pause
  end

  def clear_hands
    dealer.clear_hand
    players.each { |player| player.clear_hand }
  end

  def ask_for_bets
    players.each do |player| 
      dealer.say "#{player.name}, how much do you want to bet?"
      dealer.say "You have $#{player.money}."
      dealer.say "Bet 0 to leave this table."
      begin
        amount = gets.chomp
      end until amount.match(/^\d+$/)&& amount.to_i.between?(0, player.money)
      if amount.to_i == 0
        player.leaving = true
      else
        player.bet(amount.to_i)
      end
    end
  end

  def reset_table!
    deck.reset!
    dealer.clear_hand
    players.clear
  end

  def set_players
    dealer.say "How many players are going play? Max is #{MAXIMUM_PLAYERS}."
    begin
      players_num = gets.chomp
    end until players_num.match(/^\d$/) && players_num.to_i <= MAXIMUM_PLAYERS

    players_num.to_i.times do |i|
      puts 
      dealer.say "I've got questions for player#{i + 1}"
      players << Player.new 
    end
  end

end

GameTable.new.play
