# encoding: UTF-8
require_relative 'hand'

class Player
  include HasBlackJackHand
  attr_accessor :money, :bets, :name, :choice

  def initialize(name,money)
    @hand = []
    @bets = 0
    @money = money.to_i
    @name = name
    @choice = ''
  end

  def broke?
    bets == 0 && money == 0
  end

  def my_turn?
    (choice == '' || choice == 'h') && !busted?
  end

  def bet(amount)
    self.money -= amount
    self.bets = amount
  end

  def push
    self.money += bets
    self.bets = 0
  end

  def win
    self.money += bets * 2
    self.bets = 0
  end

  def lose
    self.bets = 0
  end

end
