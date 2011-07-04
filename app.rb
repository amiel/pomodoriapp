require "bundler/setup"
require "sinatra"

require 'dm-core'
require 'dm-migrations'
require 'do_sqlite3'

# configure :development do

# end


class Pomodoro
  include DataMapper::Resource

  property :id, Serial
  property :user, String, required: true
  property :description, String
  property :started_at, DateTime, required: true, default: proc { Time.now }
end


DataMapper.setup(:default, {
  :adapter => 'sqlite3',
  :path => 'db/development.sqlite',
})

DataMapper::Logger.new(STDOUT, :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.auto_upgrade!



get '/' do
  p Pomodoro.all
  @users = Pomodoro.all(:fields => [:user], :unique => true, :order => [:started_at.desc])
  p @users
  # TODO: find out the actual best way to do this
  @pomodoros = @users.collect { |pomodoro| Pomodoro.first :user => pomodoro.user, :order => :started_at.desc }
  p @pomodoros
  @pomodoros = @pomodoros.compact
  p @pomodoros
  erb :'index.html'
end


post '/start' do
  p params
  Pomodoro.create :user => params[:username], :description => params[:description]
end