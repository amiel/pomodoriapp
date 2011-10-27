require 'bundler/setup'

require 'erubis'
require 'sinatra'

require 'pusher'
require 'tinder'

# configure :development do

# end

APP_ROOT = Pathname.new(File.expand_path("..", __FILE__))

require APP_ROOT.join('app/models')

# You might think I'm an idiot for putting this sensitive information in a public repo.
# You might be right but dude, don't be a dick, get your own free pusher account.
# http://pusher.com
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

  def time(msg)
    puts msg
    now = Time.now
    result = yield
    puts "-- TOOK #{ Time.now - now } seconds"
    result
  end

  def campfire_login
    if ENV['CAMPFIRE_SUBDOMAIN'] && ENV['CAMPFIRE_TOKEN']
      @campfire ||= Tinder::Campfire.new(ENV['CAMPFIRE_SUBDOMAIN'], :token => ENV['CAMPFIRE_TOKEN'])
    end
  end

  def cm_campfire_room
    if (c = campfire_login)
      @campfire_room ||= c.rooms.find { |r| r.name == "CM" }
    end
  end

  def notify_campfire(msg)
    if (room = cm_campfire_room)
      room.speak msg
    end
  end

end

get '/' do
  time "POMODORO GET /" do
    @users = User.all
    @pomodoros = @users.collect(&:latest_pomodoro).compact
    erb :'index.html'
  end
end

post '/start' do
  time "POMODORO START: #{ params[:username] }" do
    pomodoro = Pomodoro.create user: params[:username], description: params[:description]

    notify_campfire("*is starting a pomodoro on \"#{ pomodoro.description }\"*")

    Pusher['pomodoro'].trigger('start', pomodoro.infos)
  end
end

post '/end' do
  time "POMODORO BREAK: #{ params[:username] }" do
    pomodoro = get_pomodoro_for_user(params[:username])
    pomodoro.update status: 'break', finish_at: Time.now

    notify_campfire("I just finished my pomodoro on \"#{ pomodoro.description }\". Break time!")

    Pusher['pomodoro'].trigger('end', pomodoro.infos)
  end
end



post '/break_end' do
  time "POMODORO FINISH: #{ params[:username] }" do

    pomodoro = get_pomodoro_for_user(params[:username])
    pomodoro.update status: 'finished'

    notify_campfire("*is ready for another pomodoro.*")

    Pusher['pomodoro'].trigger('break_end', pomodoro.infos)
  end
end

