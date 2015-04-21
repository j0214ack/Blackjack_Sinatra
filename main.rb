# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require_relative 'lib/player'

set :sessions, true

get '/' do
  session.clear
  if @player = session['player']
    erb :index
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session['player'] = Player.new(params[:player_name],params[:player_money])
  redirect '/game'
end

get '/game' do
  redirect '/game/bet' unless session['player'] && session['player'].bets != 0
  @player = session['player']
  erb :game
end

get '/game/bet' do
  redirect '/game' if session['player'] && session['player'].bets != 0

  @player = session['player']

  erb :make_bet
end

post '/game/bet' do
  session['player'].bets = params['player_bet']
  redirect '/game'
end
