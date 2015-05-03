# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'lib/player'
require_relative 'lib/deck_and_card'
require_relative 'lib/dealer'

set :sessions, true
set :protection, except: :session_hijacking

helpers do
  def check_player
    redirect '/new_player' unless session['player']
    redirect '/new_player' if session['player'].bets == 0 && session['player'].money == 0
  end

  def check_bets
    redirect '/game/bets' if session['player'].bets == 0
  end

  def build_deck(new_deck = false)
    if session['deck'] && !new_deck
      @deck = Deck.cookie_construct(session['deck'])
    else
      @deck = Deck.new(1)
    end
  end

  def all_player_clear_hand
    session['dealer'].clear_hand
    session['player'].clear_hand
  end

  def deal_flop
    all_player_clear_hand
    2.times do
      deal_card(session['dealer'], @deck)
      deal_card(session['player'], @deck)
    end
  end

  def player_lose
    bets = session['player'].bets
    session['player'].lose
    @result_msg = "You lost! You lost your $#{bets}."
    @result_type = "error"
  end

  def player_win
    bets = session['player'].bets
    session['player'].win
    @result_msg = "You won! You get $#{bets} more."
    @result_type = "success"
  end

  def player_push
    bets = session['player'].bets
    session['player'].push
    @result_msg = "You pushed with dealer! You get $#{bets} back."
    @result_type = "info"
  end

  def result
    @hide_fisrt_dealer_card = false
    session['ending_round'] = true
    @show_result = true
    if session['player'].busted?
      player_lose
    elsif session['dealer'].busted?
      player_win
    else
      case session['player'].total_points <=> session['dealer'].total_points
      when 1 then player_win
      when 0 then player_push
      when -1 then player_lose
      end
    end
    session['player'].choice = ''
  end

  def continue_on_gaming
    session['dealer'] = Dealer.new unless session['dealer']
    if !session['player'].flop_dealt? || !session['dealer'].flop_dealt?
      deal_flop
      if session['dealer'].blackjack?
        @dealer_say = "Sorry! I have blackjack!"
        result
      elsif session['player'].total_points == 21
        @dealer_say = "Great! You've hit 21 points. It's my turn now."
        @show_dealer_turn = true
        @hide_fisrt_dealer_card = false
      else
        @show_player_turn = true
      end
    elsif session['player'].my_turn?
      if session['dealer'].blackjack?
        @dealer_say = "Sorry! I have blackjack!"
        result
      elsif session['player'].total_points == 21
        @dealer_say = "Great! You've hit 21 points. It's my turn now."
        @show_dealer_turn = true
        @hide_fisrt_dealer_card = false
      else
        @show_player_turn = true
      end
    elsif session["ending_round"]
      result
    else #dealer turn
      case session["dealer"].choice
      when '' then @dealer_say = "It's my turn."
      when 'h' then @dealer_say = "I chose to hit."
      when 's' then @dealer_say = "I chose to stay."
      end
      @show_dealer_turn = true
      @hide_fisrt_dealer_card = false
    end
  end

  def dealer_turn
    @hide_fisrt_dealer_card = false
    if session['dealer'].hit_or_stay == 'h'
      deal_card(session['dealer'], @deck)
      if session['dealer'].busted?
        @dealer_say = "I chose to hit.\n Oops, I am busted."
        @show_result = true
        result
      else
        @dealer_say = "I chose to hit."
        @show_dealer_turn = true
      end
    elsif session['dealer'].hit_or_stay == 's'
      @dealer_say = "I chose to stay."
      @show_result = true
      result
    end
  end

  def player_turn
    if params['hit_or_stay'] == 'h'
      if session['player'].busted?
        @dealer_say = "You've already busted. Don't cheat!."
        continue_on_gaming
      elsif session['player'].choice == 's'
        @dealer_say = "You've already chose to stay. Don't cheat!"
        continue_on_gaming
      else
        deal_card(session["player"], @deck)
        if session['player'].busted?
          @dealer_say = "You're busted! You lost."
          session['player'].choice = "s"
          result
        elsif session['player'].total_points == 21
          @dealer_say = "Great! You've hit 21 points. It's my turn now."
          @show_dealer_turn = true
          @hide_fisrt_dealer_card = false
        else
          @show_player_turn = true
          session['player'].choice = 'h'
        end
      end
    elsif params['hit_or_stay'] == 's'
      session['player'].choice = 's'
      @dealer_say = "You chose to stay. Then it's my turn."
      @show_dealer_turn = true
      @hide_fisrt_dealer_card = false
    end
  end

  def deal_card(receiver, deck)
    if deck.size < 10
      @dealer_say = "Too few cards in the deck, preparing an new one.."
      deck.reset!
    end
    receiver.add_a_card(deck.deal_a_card)
  end

end # helpers do

before do
  @hide_fisrt_dealer_card = true
end

get '/' do
  check_player
  erb :index
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  name = params[:player_name].strip
  money = params[:player_money]
  if money.match(/^\d+$/) && money.to_i > 0
    session['player'] = Player.new(name,money.to_i)
    redirect '/game/bets'
  else
    @input_error = "You must enter a positive number for your money."
    @name = name
    erb :new_player
  end
end

get '/game' do
  check_player
  check_bets
  build_deck
  continue_on_gaming
  session['deck'] = @deck.to_cookie

  erb :game
end

post '/game/new' do
  check_player
  if session['ending_round'] == true
    session['ending_round'] = false
    all_player_clear_hand
    redirect "/game/bets"
  else
    redirect "/game"
  end
end

post '/game' do
  check_player
  check_bets
  build_deck
  if params['turn'] == "player_turn"
    player_turn
  elsif params['turn'] == "dealer_turn"
    dealer_turn
  else
    redirect '/game'
  end
  session['deck'] = @deck.to_cookie

  erb :game
end

get '/game/bets' do
  check_player
  erb :make_bets
end

post '/game/bets' do
  check_player
  if params['player_bets'].match(/^\d+$/)
    if params['player_bets'].to_i.between?(1,session['player'].money)
      bets = params['player_bets'].to_i
      session['player'].bets = bets
      session['player'].money -= bets
      redirect '/game'
    end
  end
  @input_error = "You must bet between $1 to $#{session['player'].money}."
  erb :make_bets
end
