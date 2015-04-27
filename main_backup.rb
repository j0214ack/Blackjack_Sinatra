# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'pry'
require_relative 'lib/player'
require_relative 'lib/deck_and_card'
require_relative 'lib/dealer'


GAME_STAGES = {round_start: "1", turn_player: "2", turn_dealer: "3", round_end: "4"}
set :sessions, true

helpers do
  def check_player
    redirect '/new_player' unless session['player']
  end

  def check_bets
    redirect '/game/bets' if session['player'].bets == 0
  end

  def resume_game
    @deck = Deck.cookie_construct(session['deck'])
  end

  def round_start
    if session['deck']
      @deck = Deck.cookie_construct(session['deck'])
    else
      @deck = Deck.new(4) # 4 sets of cards
    end
    session[:dealer] = Dealer.new
    session[:player].choice = ""
    session[:player].clear_hand
    2.times do 
      session[:dealer].add_a_card(@deck.deal_a_card)
      session[:player].add_a_card(@deck.deal_a_card)
    end
    if session[:dealer].blackjack?
      change_game_stage(GAME_STAGES[:round_end])
    else
      change_game_stage(GAME_STAGES[:turn_player])
    end
    session['deck'] = @deck.to_cookie
  end

  def turn_player
    if session[:player].choice == 'h'
      session[:player].add_a_card(@deck.deal_a_card)
    elsif session[:player].choice == 's'
      change_game_stage(GAME_STAGES[:turn_dealer])
      game_play
    end

    if session[:player].busted? || session[:player].blackjack? 
      change_game_stage(GAME_STAGES[:round_end])
    end
    @error = "player turn"
  end

  def turn_dealer
    #binding.pry
    if session[:dealer].hit_or_stay == 'h'
      session[:dealer].add_a_card(@deck.deal_a_card)
    else
      change_game_stage(GAME_STAGES[:round_end])
    end
    if session[:dealer].busted?
      change_game_stage(GAME_STAGES[:round_end])
    end
    @error = "dealer turn"
  end

  def change_game_stage(stage)
    session[:game_stage] = stage
  end

  def player_result(result)
    case result
    when :win 
      session[:player].win
      @result_msg = "You won!"
      @result_type = "success"
    when :push 
      session[:player].push
      @result_msg = "You made a push!"
      @result_type = "block"
    when :lose 
      session[:player].win
      @result_msg = "You lose!"
      @result_type = "error"
    end 
  end

  def round_result
    if session[:dealer].blackjack?
      player.blackjack? ?  player_result(:push) : player_result(:lose)
    else
      if session[:player].busted?
        player_result(:lose)
      else
        if session[:dealer].busted?
          player_result(:win)
        else
          case session[:dealer].total_points <=> session[:player].total_points
          when 1 then player_result(:lose)
          when 0 then player_result(:push)
          when -1 then player_result(:win)
          end
        end
      end
    end
  end

  def game_play
    #binding.pry
    case session[:game_stage]
    when GAME_STAGES[:round_start]
      round_start
    when GAME_STAGES[:turn_player]
      resume_game
      turn_player
      session['deck'] = @deck.to_cookie
    when GAME_STAGES[:turn_dealer]
      resume_game
      turn_dealer
      session['deck'] = @deck.to_cookie
    when GAME_STAGES[:round_end]
      resume_game
      round_result
    end
  end

end # helpers do

before do
  pass if request.path_info == "/new_player"
  check_player
  pass if request.path_info == "/game/bets"
  check_bets
  @show_continue = false
  @show_hit_or_stay = false
  @hide_first_card = true
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
  if session[:game_stage].nil? || session[:game_stage].empty?
    change_game_stage(GAME_STAGES[:round_start])
    game_play
  end
  @player_choice = session[:player].choice
  session[:player].choice = ""
  case session[:game_stage]
  when GAME_STAGES[:turn_player]
    @show_hit_or_stay = true
  when GAME_STAGES[:turn_dealer], GAME_STAGES[:round_end]
    @hide_first_card = false
    @show_continue = true
  end
  erb :game
end

post '/game/continue' do
  session[:game_stage] = params[:change_to_stage]
  game_play
  redirect :game
end

post '/game/hit_or_stay' do
  session['player'].choice = params['hit_or_stay']
  game_play
  redirect :game
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
