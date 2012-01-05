require 'activerecord'
require 'active_record_setup'
require 'active_record_to_simpledb'

class TicketSale < ActiveRecord::Base
  include ActiveRecordToSimpledb::Callbacks::Create
end

describe ActiveRecordToSimpledb do

  context "conection" do

    it "does authenticate with credentails" do
      RightAws::SdbInterface.should_receive(:new).with(AWS.key,AWS.secret)
      ActiveRecordToSimpledb.aws_connect
    end

    it "connects to simpledb" do
      RightAws::ActiveSdb.should_receive(:establish_connection)
      ActiveRecordToSimpledb.connect
    end

  end

  it "saves the object when inserted in model" do
    attr = { "id" => 1, "event_id" => 123, "title" => "Hello"}
    ActiveRecordToSimpledb::Client.should_receive(:create).with("ticketsale", attr)
    TicketSale.create(attr)
  end

  it "uses resque to send the object" do
  end

  it "does nothing when rails env is test" do
    RAILS_ENV = "test"
    attr = {"id" => 4, "event_id" => 123, "title" => "Hello" }
    TicketSale.create(attr)
    t = ActiveRecordToSimpledb::Query.find("ticketsale", 4)
    t[:attributes].should == {}
  end

  context "integration" do


    before(:all) do
      @attr = {"id" => 1, "event_id" => 123, "title" => "Hello" }
      TicketSale.create(@attr)
    end

    it "retrevies an object from simple db" do
      t = ActiveRecordToSimpledb::Query.find("ticketsale", 2)
      t[:attributes]["title"].should == ["Hello"]
    end

    it "queries for event id" do
      query = ["select * from ticketsale where event_id=?", '123']
      t = ActiveRecordToSimpledb::Query.find_by_sql( query )
      t[:items][0].first[1]["title"].should == ["Hello"]
    end
  end

end
