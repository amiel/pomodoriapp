
require 'dm-core'
require 'dm-migrations'
require 'do_sqlite3'

class User
  include DataMapper::Resource

  has n, :pomodoros

  property :id, Serial
  property :name, String, required: true

  def latest_pomodoro
    pomodoros.first order: :started_at.desc
  end

  def to_s
    name
  end
end


class Pomodoro
  include DataMapper::Resource

  belongs_to :user

  property :id, Serial
  property :user_id, Integer
  property :description, String
  property :started_at, DateTime, required: true, default: proc { Time.now }
  property :finish_at, DateTime
  property :status, String, required: true, default: 'started'

  def finish_at
    # Not sure what the best way to advance a datetime...
    # DateTime#+ advances by number of days instead of seconds.
    super || (started_at.to_time + (25*60) + (120*60)).to_datetime
  end

  def user=(user_name)
    if String === user_name
      super User.first_or_create(name: user_name)
    else
      super
    end
  end

  def friendly_status
    (@statuses ||= {
      'started' => 'Focused',
      'break' => 'Break',
      'finished' => 'Done',
    })[status]
  end

  def infos
    {
      name: user.name,
      description: description,
      friendly_status: friendly_status,
      status: status,
      started_at: started_at,
      finish_at: finish_at,
    }
  end
end


DataMapper.setup(:default, {
  :adapter => 'sqlite3',
  :path => 'db/development.sqlite',
})

DataMapper::Logger.new(STDOUT, :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.auto_upgrade!
