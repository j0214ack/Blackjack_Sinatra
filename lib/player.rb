# encoding: UTF-8
require_relative 'hand'

class Player
  include HasHand
  attr_accessor :money, :bets, :name, :choice
  
  def initialize(name,money)
    @hand = []
    @bets = 0
    @money = money.to_i
    @name = name
    @choice = ''
  end

  def choice
    case @choice
    when 's'
      'Stay'
    when 'h'
      'Hit'
    else
      ''
    end
  end

  def bet(amount)
    self.money -= amount
    self.bets = amount
  end

  def push
    #puts "#{name} made a push with dealer. #{name} gets #{bets} dollars back."
    self.money += bets
    self.bets = 0
  end

  def win
    #puts "#{name} won! #{name} gets #{bets * 2} dollars back."
    self.money += bets * 2
  end

  def lose
    #puts "#{name} lose! #{name} can't get his #{bets} dollars back."
  end
end
