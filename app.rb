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
  property :started_at, DateTime, required: true, default: proc { Time.now }
end

DataMapper.setup(:default, 'sqlite::memory:')
DataMapper::Logger.new(STDOUT, :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.auto_migrate!



get '/' do
  @users = Pomodoro.all(:fields => [:user], :unique => true, :order => [:started_at.desc])
  # TODO: find out the actual best way to do this
  @pomodoros = @users.collect { |user| Pomodoro.first :user => user, :order => :started_at.desc }

  erb :'index.html'
end


post '/start' do
  Pomodoro.create :user => params[:username]
end