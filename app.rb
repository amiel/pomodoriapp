require 'bundler/setup'

require 'erubis'
require 'sinatra'

require 'pusher'

# configure :development do

# end

APP_ROOT = Pathname.new(File.expand_path("..", __FILE__))

require APP_ROOT.join('app/models')

Pusher.app_id = '8673'
Pusher.key = '322ec20ec6e1389ccd71'
Pusher.secret = '5fd3d7430d6230d40550'


Tilt.register :erb, Tilt[:erubis]

helpers do
  def get_pomodoro_for_user(user_name)
    user = User.first name: user_name
    raise "No user for /end user(#{ user_name })" unless user
    pomodoro = user.latest_pomodoro
    raise "No pomodoro for /end user(#{ user_name })" unless pomodoro
    return pomodoro
  end
end

get '/' do
  @users = User.all
  @pomodoros = @users.collect(&:latest_pomodoro).compact
  erb :'index.html'
end

post '/start' do
  pomodoro = Pomodoro.create user: params[:username], description: params[:description]
  Pusher['pomodoro'].trigger('start', pomodoro.infos)
end

post '/end' do
  pomodoro = get_pomodoro_for_user(params[:username])
  pomodoro.update status: 'break', finish_at: Time.now

  Pusher['pomodoro'].trigger('end', pomodoro.infos)
end



post '/break_end' do
  pomodoro = get_pomodoro_for_user(params[:username])
  pomodoro.update status: 'finished'

  Pusher['pomodoro'].trigger('break_end', pomodoro.infos)
end

