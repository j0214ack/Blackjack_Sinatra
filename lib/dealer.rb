# encoding: UTF-8
require_relative 'hand'

class Dealer
  include HasHand

  def initialize
    @hand = []
  end

  def hit_or_stand
    if total_points < 17
      'h'
    else
      's'
    end
  end

  def show_hand(hide = true)
    super(hide)
  end
end
