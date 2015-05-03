# encoding: UTF-8
module HasBlackJackHand
  attr_accessor :hand

  def blackjack?
    hand.size == 2 && total_points == 21
  end

  def busted?
    total_points > 21
  end

  def flop_dealt?
    hand.size >= 2
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

  #def show_hand(hide_fisrt_card = false)
    #cards_strings = hand.map{ |card| card.to_s }
    #cards_strings[0] = "🂠 ??" if hide_fisrt_card
    #cards_strings.join(" | ")
  #end

  def show_hand(hide_first_card = false)
    cards_urls = hand.map{ |card| card.to_url }
    cards_urls[0] = "/images/cards/cover.jpg" if hide_first_card
    cards_urls
  end

  def add_a_card(card)
    hand << card
  end
end
