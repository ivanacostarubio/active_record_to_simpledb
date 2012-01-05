require 'right_aws'
require 'sdb/active_sdb'
require 'json'

class AWS
  def self.root
    rails_root = (Rails.version < "2.1.2") ? RAILS_ROOT : Rails.root
    YAML::load(IO.read(File.join(rails_root, 'config', 'aws.yml')))
  end

  def self.key
    AWS.root[RAILS_ENV]['access_key_id']
  end

  def self.secret
    AWS.root[RAILS_ENV]['secret_access_key']
  end
end



class ActiveRecordToSimpledb

  # Public: It connect to aws
  #
  # Example
  #
  #  ActiveRecordToSimpledb.aws_connect
  #
  # Return the connection object to AWS
  def self.aws_connect
    RightAws::SdbInterface.new(AWS.key, AWS.secret)
  end

  #
  # Public: stablishes the connection
  #
  def self.connect
    RightAws::ActiveSdb.establish_connection
  end

  #
  # Public: It created a new Simpledb domain
  #
  # string  - The name of the domain we want to create
  # Example
  #
  # ActiveRecordToSimpledb.create_domain("new_domain")
  #
  def self.create_domain(name)
    ActiveRecordToSimpledb.aws_connect.create_domain(name)
  end

  class Client
    #
    # Public: This method create simpledb records
    #
    # hash - model attributes
    #
    def self.create(domain,attr)
      ActiveRecordToSimpledb.create_domain(domain)
      ActiveRecordToSimpledb.aws_connect.put_attributes(domain, attr["id"], attr)
    end
  end

  module Query

    #
    # Public: It finds a Simpledb record given the domain and record id
    #
    # string - the name of the domain to query
    # integer - the id of the record in ActiveRecord
    #
    def self.find(domain, id)
      ActiveRecordToSimpledb.aws_connect.get_attributes(domain, id)
    end

    #
    # Public: It finds a Simpledb record using a sqlish query
    # array / string - A SQLish array with the query
    #
    # Example:
    #
    # query = ["select * from ticket_sales where event_id=?", '123']
    # ActiveRecordToSimpledb::Query.find_by_sql( query )
    #
    def self.find_by_sql(query)
      ActiveRecordToSimpledb.aws_connect.select(query)
    end
  end

  module Callbacks

    module Create

      def domain_name
        self.class.to_s.downcase
      end
      #
      # Private: it create a resque job in we are not in test. Otherwise, it create the simpledb object
      #
      def send_object_to_simpledb
        if RAILS_ENV == "test"
          ActiveRecordToSimpledb::Client.create(domain_name, self.attributes)
        else
          Resque.enqueue(ActiveRecordToSimpledb::Resque::Create, self.attributes)
        end
      end

      #
      # Private: some meta programing to create a callback in the model class.
      #
      def self.included(base)
        base.class_eval do
          after_create :send_object_to_simpledb
        end
      end
    end
  end

  #
  # Private: a module with the resque jos
  #
  module Resque
    class Create
      @queue = :active_record_to_simple_db_create
      def self.perform(attributes)
        ActiveRecordToSimpledb::Client.create(self.attributes)
      end
    end
  end
end


