# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'lib/player'
require_relative 'lib/deck_and_card'
require_relative 'lib/dealer'

set :sessions, true

helpers do
  def check_player
    redirect '/new_player' unless session['player']
  end

  def check_bets
    redirect '/game/bets' if session['player'].bets == 0
  end

  def rebuild_deck
    @deck = Deck.cookie_construct(session['deck'])
  end

end # helpers do

before do
  pass if request.path_info == "/new_player"
  check_player
  pass if request.path_info == "/game/bets"
  check_bets
end

get '/' do
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
end

post '/game/continue' do
  session[:game_stage] = params[:change_to_stage]
  game_play
  redirect :game
end

post '/game/hit_or_stay' do
end

get '/game/bets' do
  erb :make_bets
end

post '/game/bets' do
  if params['player_bets'].match(/^\d+$/)
    if params['player_bets'].to_i.between?(1,session['player'].money)
      session['player'].bets = params['player_bets'].to_i
      redirect '/game'
    end
  end
  @input_error = "You must bet between $1 to $#{session['player'].money}."
  erb :make_bets
end
