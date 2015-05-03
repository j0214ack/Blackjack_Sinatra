# encoding: UTF-8
class Card
  SUITS = {s: "♠", h: "♥", d: "♦", c: "♣"}
  FACES = %w(A 2 3 4 5 6 7 8 9 T J Q K)
  attr_accessor :suit, :face

  def initialize(suit,face)
    @suit = suit
    @face = face
  end

  def to_s
    "🂠 #{SUITS[suit]}#{face} "
  end

  def to_url
    result = ""
    case suit
    when :s
      result += "spades_"
    when :h
      result += "hearts_"
    when :d
      result += "diamonds_"
    when :c
      result += "clubs_"
    end

    case face
    when "A" then result += "ace"
    when "T" then result += "10"
    when "J" then result += "jack"
    when "Q" then result += "queen"
    when "K" then result += "king"
    else result += face
    end

    result = "/images/cards/#{result}.jpg"
  end

  def to_points
    case face
    when 'J', 'Q', 'K' then 10
    when 'A' then 1
    else FACES.index(face) + 1
    end
  end

  def order
    FACES.index(face)
  end

  # in order to become a key in a Hash
  def eql?(other)
    suit == other.suit
    face == other.face
  end

  def hash
    [suit, face].hash
  end
end

class Deck
  attr_accessor :cards, :deck_num

  def size
    cards.values.inject(:+)
  end

  def initialize(input = 4)
    deck_num = input
    @deck_num = deck_num
    @cards = (input == 0) ? {} : new_deck
  end

  def to_cookie
    deck_cookie = { deck_num: deck_num }
    Card::SUITS.keys.each do |suit|
      deck_cookie[suit] = count_feature(suit)
    end
    deck_cookie
  end

  def count_feature(suit)
    feature = 0
    cards.select{|card,num| card.suit == suit}.each do |card,num|
      feature += num * ((deck_num + 1) ** card.order)
    end
    feature
  end

  def self.cookie_construct(cookie_value)
    deck = self.new
    deck.deck_num = deck_num = cookie_value[:deck_num]
    Card::SUITS.keys.each do |suit|
      feature_value = cookie_value[suit]
      Card::FACES.each do |face|
        deck.cards[Card.new(suit,face)] = feature_value % (deck_num + 1)
        feature_value /= (deck_num + 1)
      end
    end
    deck
  end

  def deal_a_card
    card = cards.select{|card, num| num > 0}.keys.sample
    cards[card] -= 1
    card
  end

  def reset!
    self.cards = new_deck
  end

  private

  def new_deck
    cards = {}
    Card::SUITS.keys.product(Card::FACES).each do |card|
      cards[Card.new(*card)] = deck_num
    end
    cards
  end

end
