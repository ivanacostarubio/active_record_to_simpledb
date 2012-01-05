RAILS_ENV = "test"

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new(File.dirname(__FILE__) + "debug.log")
ActiveRecord::Base.establish_connection(config['test'])

def rebuild_model options = {}
  ActiveRecord::Base.connection.create_table :ticket_sales, :force => true do |table|
    table.column :event_id, :integer
    table.column :title, :string
  end
end

rebuild_model


