require 'activerecord'
require 'active_record_setup'
require 'active_record_to_simpledb'

class TicketSale < ActiveRecord::Base
  include ActiveRecordToSimpledb::Callbacks::Create
end

describe ActiveRecordToSimpledb do

  before(:all) do
    RAILS_ENV = "prueba"
  end

  before(:each) do
    TicketSale.destroy_all
  end

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

  context "integration" do
    before(:all) do
      @attr = {"id" => 1, "event_id" => 123, "title" => "Hello" }
      @ticket_sale = TicketSale.create(@attr)
    end

    it "retrevies an object from simple db" do
      t = ActiveRecordToSimpledb::Query.find("ticketsale", @ticket_sale.id)
      t[:attributes]["title"].should == ["Hello"]
    end

    it "queries for event id" do
      query = ["select * from ticketsale where event_id=?", '123']
      t = ActiveRecordToSimpledb::Query.find_by_sql( query )
      t[:items][0].first[1]["title"].should == ["Hello"]
    end
  end

  it "deletes the record from simpledb" do
    attr = { "event_id" => 321 , "title" => "delete" }
    r = TicketSale.create(attr)
    query = ["select * from ticketsale where title=?", "delete"]
    t = ActiveRecordToSimpledb::Query.find_by_sql(query)
    ActiveRecordToSimpledb::Destroy.by_key("ticketsale",r.id)
    t[:items].should == []
  end

  context " not sending records in test because we'll pollute the users tests" do
    before(:each) do
      RAILS_ENV = "test"
    end

    after(:each) do
      RAILS_ENV = "prueba"
    end

    it "does nothing when rails env is test" do
      attr = {"id" => 4, "event_id" => 123, "title" => "Hello" }
      ticket_sale = TicketSale.create(attr)
      t = ActiveRecordToSimpledb::Query.find("ticketsale", ticket_sale.id)
      t[:attributes].should == {}
    end
  end

  context "recreating records from simpledb" do

    before(:each) do
      ActiveRecordToSimpledb.aws_connect.delete_domain('ticketsale')
      TicketSale.destroy_all
    end

    it "recreates one a record" do
      ticket = TicketSale.create(:title => "resurrected", :event_id => "33137")
      result = ActiveRecordToSimpledb::Query.find("ticketsale", ticket.id)
      result[:attributes]["title"].should == ["resurrected"]

      TicketSale.destroy_all
      TicketSale.count.should == 0

      ActiveRecordToSimpledb::Recover.from(TicketSale, ticket.id)
      TicketSale.count.should == 1

      TicketSale.last.title.should == "resurrected"

    end

    it "recreates two records" do
      ticket_1 = TicketSale.create(:title => "death", :event_id => "888")
      ticket_2 = TicketSale.create(:title => "muerto", :event_id => "888")
      TicketSale.destroy_all


      query = ["select * from ticketsale where event_id =?", "888"]
      ActiveRecordToSimpledb::Recover.from_query(TicketSale, query)
      tickets = TicketSale.all

      tickets[0].title.should == "death"
      tickets[1].title.should == "muerto"

    end
  end

end
