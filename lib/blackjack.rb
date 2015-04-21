require 'pry'

module Pauseable
  def pause
    puts "(press enter to continue...)"
    gets
  end
end

module HasHand
  def blackjack?
    hand.size == 2 && total_points == 21 
  end

  def busted?
    total_points > 21
  end

  def total_points
    result = 0
    aces = 0
    hand.each do |card|
      result += card.to_points
      aces += 1 if card.to_points == 1
    end
    result += 10 if (aces != 0 && (result + 10 <= 21))
    result 
  end

  def clear_hand
    hand.clear
  end

  def show_hand(hide_fisrt_card = false)
    cards_strings = hand.map{ |card| card.to_s }
    cards_strings[0] = "🂠 ??" if hide_fisrt_card
    cards_strings.join(" | ")
  end

  def add_a_card(card)
    hand << card
  end
end

class Player
  include Pauseable
  include HasHand
  attr_accessor :hand, :money, :bets, :name, :leaving
  
  def initialize
    puts "What's your name?"
    name = gets.chomp.strip

    puts "How much money do you have?"
    begin
      money = gets.chomp
    end until money.match /^\d+$/

    @hand = []
    @bets = 0
    @money = money.to_i
    @name = name
    @leaving = false
  end

  def hit_or_stand
    if total_points == 21
      puts "You have a blackjack!"
      pause
      return 's'
    end
    begin
      puts "#{name}, do you wish to 1) hit or, 2) stand?"
      choice = gets.chomp
    end until %w(1 2).include? choice
    choice == '1' ? 'h' : 's'
  end

  def bet(amount)
    self.money -= amount
    self.bets = amount
  end

  def push
    puts "#{name} made a push with dealer. #{name} gets #{bets} dollars back."
    self.money += bets
    self.bets = 0
  end

  def win
    puts "#{name} won! #{name} gets #{bets * 2} dollars back."
    self.money += bets * 2
  end

  def lose
    puts "#{name} lose! #{name} can't get his #{bets} dollars back."
  end
end

class Dealer
  include Pauseable
  include HasHand
  attr_accessor :hand

  def initialize
    @hand = []
  end

  def hit_or_stand
    say "Let me think....."
    pause
    if total_points < 17
      say "I want to hit!"
      pause
      'h'
    else
      say "I want to stand"
      pause
      's'
    end
  end

  def say(sentence)
    puts "=> #{sentence}"
  end
end

class Card
  SUITS = {s: "♠", h: "♥", d: "♦", c: "♣"}
  FACES = %w(A 2 3 4 5 6 7 8 9 T J Q K)
  attr_accessor :suit, :face

  def initialize(card_info)
    @suit = card_info[0]
    @face = card_info[1]
  end

  def to_s
    "🂠 #{SUITS[suit]}#{face}"
  end

  def to_points
    case face
    when 'J', 'Q', 'K' then 10
    when 'A' then 1
    else FACES.index(face) + 1
    end
  end
end

class Deck
  attr_accessor :cards, :deck_num

  def new_deck
    a_deck = Card::SUITS.keys.product(Card::FACES).map do |card|
      Card.new(card)
    end
    a_deck *= deck_num
    a_deck.shuffle
  end

  def initialize(deck_num)
    @deck_num = deck_num
    @cards = new_deck
  end

  def deal_a_card
    cards.pop
  end

  def shuffle!
    cards.shuffle!
  end

  def reset!
    self.cards = new_deck
  end
end

class GameTable
  include Pauseable
  attr_accessor :dealer, :players, :deck
  MAXIMUM_PLAYERS = 3

  def initialize(deck_num = 4)
    @dealer = Dealer.new
    @players = []
    @deck = Deck.new(deck_num)
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
