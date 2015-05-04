# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'lib/player'
require_relative 'lib/deck_and_card'
require_relative 'lib/dealer'

use Rack::Session::Cookie :key => 'rack.session',
                          :path => '/',
                          :secret => 'aaabbc_tlbj'

helpers do
  def check_player
    redirect '/player/new' unless session['player']
    redirect '/player/broke' if session['player'].broke?
  end

  def check_bets
    redirect '/game/bets' if session['player'].bets == 0
  end

  def build_deck(new_deck = false)
    if session['deck'] && !new_deck
      @deck = Deck.cookie_construct(session['deck'])
    else
      @deck = Deck.new(4)
    end
  end

  def all_player_clear_hand
    session['dealer'].clear_hand if session['dealer']
    session['player'].clear_hand if session['player']
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

  def check_before_player_turn
    if session['dealer'].blackjack?
      @dealer_say = "Sorry! I have blackjack!"
      result
    elsif session['player'].busted?
      @dealer_say = "You're busted! You lost."
      result
    elsif session['player'].total_points == 21
      @dealer_say = "Great! You've hit 21 points. It's my turn now."
      @show_dealer_turn = true
      @hide_fisrt_dealer_card = false
    else
      @show_player_turn = true
    end
  end

  def continue_on_gaming
    session['dealer'] = Dealer.new unless session['dealer']
    if !session['player'].flop_dealt? || !session['dealer'].flop_dealt?
      deal_flop
      check_before_player_turn
    elsif session['player'].my_turn?
      check_before_player_turn
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
        result
      else
        @dealer_say = "I chose to hit."
        @show_dealer_turn = true
      end
    elsif session['dealer'].hit_or_stay == 's'
      @dealer_say = "I chose to stay."
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
        session['player'].choice = 'h'
        check_before_player_turn
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

before "/game*" do
  check_player
  @hide_fisrt_dealer_card = true
end

before "/game" do
  check_bets
  build_deck
end

get '/' do
  check_player
  erb :index
end

get '/player/broke' do
  redirect "/player/new" unless session['player']
  redirect "/game" unless session['player'].broke?

  erb :player_broke
end

post '/player/broke' do
  redirect "/player/new" unless session['player']
  redirect "/game" unless session['player'].broke?
  money = params[:player_money]
  if money.match(/^\d+$/) && money.to_i > 0
    session['player'].money = money.to_i
    redirect '/game/bets'
  else
    @input_error = "You must enter a positive number for your money."
    @name = name
    erb :player_broke
  end
end

get '/player/new' do
  erb :new_player
end

post '/player/new' do
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
  continue_on_gaming
  session['deck'] = @deck.to_cookie

  erb :game
end

post '/game/new' do
  if session['ending_round'] == true
    session['ending_round'] = false
    all_player_clear_hand
    redirect "/game/bets"
  else
    redirect "/game"
  end
end

post '/game' do
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
  erb :make_bets
end

post '/game/bets' do
  all_player_clear_hand
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
