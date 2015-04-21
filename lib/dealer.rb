# encoding: UTF-8
require_relative 'hand'

class Dealer
  include HasHand

  def initialize
    @hand = []
  end

  def hit_or_stand
    #say "Let me think....."
    #pause
    if total_points < 17
      #say "I want to hit!"
      #pause
      'h'
    else
      #say "I want to stand"
      #pause
      's'
    end
  end

  def say(sentence)
    #puts "=> #{sentence}"
  end
end
