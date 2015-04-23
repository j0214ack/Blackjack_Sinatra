# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'lib/player'
require_relative 'lib/deck_and_card'
require_relative 'lib/dealer'


GAME_STAGES = {round_start: 1, turn_player: 2, turn_dealer: 3, round_start: 4}
set :sessions, true

helpers do
  def check_player
    #binding.pry
    redirect '/new_player' unless session['player']
  end

  def check_bets
    redirect '/game/bets' if session['player'].bets == 0
  end

  def resume_game
    @dealer = session['dealer']
    @deck = Deck.cookie_construct(session['deck'])
  end

  def game_play
    case @game_stage
    when GAME_STAGES[:round_start]
      if session['deck']
        @deck = Deck.cookie_construct(session['deck'])
      else
        @deck = Deck.new(4) # 4 sets of cards
      end
      @dealer = Dealer.new
      @player.clear_hand
      2.times do 
        @dealer.add_a_card(@deck.deal_a_card)
        @player.add_a_card(@deck.deal_a_card)
      end
      # TODO
      # check dealer blackjack
      # if true 
      # set stage to round_end
      # else turn_player
      @game_stage = GAME_STAGES[:turn_player]
      game_play
    when GAME_STAGES[:turn_player]
      # TODO
      # normal game logic
      # check busted or not, blackjack or not
      resume_game
      if @player.choice == 'h'
        @player.add_a_card(@deck.deal_a_card)
      else
        @game_stage = GAME_STAGES[:turn_dealer]
      end
      @error = "player turn"
    when GAME_STAGES[:turn_dealer]
      # TODO
      # normal game logic
      # check busted or not
      resume_game
      if @dealer.hit_or_stay == 'h'
        @dealer.add_a_card(@deck.deal_a_card)
      else
        @game_stage = GAME_STAGES[:round_start]
      end
      @error = "dealer turn"
    when GAME_STAGES[:round_start]
      # TODO
      # normal game logic
      # compare winner
      @error = "end turn"
    end
  end
end

before do
  pass if request.path_info == "/new_player"
  check_player
  @player = session['player']
  pass if request.path_info == "/game/bets"
  check_bets
end

after "/game" do
  session['player'] = @player
  session['dealer'] = @dealer
  session['deck'] = @deck.to_cookie
  session['game_stage'] = @game_stage
end

get '/' do
  @player = session['player']
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
  @game_stage = session['game_stage']
  if @game_stage == nil
    @game_stage = GAME_STAGES[:round_start]
  end
  game_play
  erb :game
end

post '/game/hit_or_stay' do
  session['player'].choice = params['hit_or_stay']
  redirect :game
end

get '/game/bets' do
  erb :make_bets
end

post '/game/bets' do
  if params['player_bets'].match(/^\d+$/)
    if params['player_bets'].to_i.between?(1,@player.money)
      session['player'].bets = params['player_bets'].to_i
      redirect '/game'
    end
  end
  @input_error = "You must bet between $1 to $#{session['player'].money}."
  erb :make_bets
end
