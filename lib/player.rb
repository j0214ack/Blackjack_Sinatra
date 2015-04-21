# encoding: UTF-8
require_relative 'hand'

class Player
  include HasHand
  attr_accessor :money, :bets, :name
  
  def initialize(name,money)
    @hand = []
    @bets = 0
    @money = money.to_i
    @name = name
  end

  def hit_or_stand
    if total_points == 21
      #puts "You have a blackjack!"
      return 's'
    end
    begin
      #puts "#{name}, do you wish to 1) hit or, 2) stand?"
      choice = gets.chomp
    end until %w(1 2).include? choice
    choice == '1' ? 'h' : 's'
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
