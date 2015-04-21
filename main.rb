require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do
  "Hello, player!"
end

get '/new_player' do
  erb :new_player
end


