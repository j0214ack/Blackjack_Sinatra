# encoding: UTF-8
require_relative 'hand'

class Dealer
  include HasBlackJackHand
  attr_accessor :choice

  def initialize
    @hand = []
  end

  def hit_or_stay
    if total_points < 17
      self.choice = 'h'
    else
      self.choice = 's'
    end
    choice
  end

  def show_hand(hide = true)
    super(hide)
  end
end
