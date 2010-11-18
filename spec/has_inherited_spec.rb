require 'spec_helper'


class Seo < ActiveRecord::Base
  is_inheritable
end

class Industry < ActiveRecord::Base
  has_inherited :seo, :from => Seo
  has_many :clients
end

class Client < ActiveRecord::Base
  belongs_to :industry
  has_many :stores
  has_inherited :seo, :from => [:industry, :seo], :inherit_class => 'Seo'
end

class Store < ActiveRecord::Base
  belongs_to :client
  has_inherited :seo, :from => [:client, :seo], :inherit_class => 'Seo'
end

describe "HasInherited" do

  before do
    ActiveRecord::Base.logger = Logger.new('test.log')
    ActiveRecord::Base.logger.level = Logger::DEBUG
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
    ActiveRecord::Schema.suppress_messages do
      ActiveRecord::Schema.define(:version => 1) do
        create_table :seos do |t|
          t.integer :inheritable_id
          t.string  :inheritable_type
          t.string  :name, :limit => 50, :null => false
          t.string  :value
          t.string  :value_type
        end

        create_table :industries do |t|
          t.name :string
          t.timestamps
        end

        create_table :clients do |t|
          t.name :string
          t.references :industry
          t.timestamps
        end

        create_table :stores do |t|
          t.name :string
          t.references :client
          t.timestamps
        end

      end
    end
  end

  after do
    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.drop_table(t)
    end
  end

  it 'should have a value' do
    s = Seo.new
    s.value = "Some Title"
    s.value.should.equal "Some Title"
  end

  it "has the ability to set global variables" do
    Seo.global.title = "Title"
    Seo.global.title.should.equal "Title"
  end

  it "should be able to set variables" do
    Seo.global.title = "Title"
    industry = Industry.create
    industry.seo.title.should.equal "Title"
  end

  it "should work with two levels of nesting" do
    Seo.global.title = "SEO Title"
    industry = Industry.create
    client = industry.clients.create
    client.seo.title.should.equal 'SEO Title'
  end

  it "should work with three levels of nesting" do
    Seo.global.title = "SEO Title"
    industry = Industry.create
    client = industry.clients.create
    client.seo.title.should.equal "SEO Title"
    client.seo.title = "Client Title"
    client.seo.title.should.equal "Client Title"
  end

  it "Should allow you to see all the custom values" do
    Seo.global.title = "SEO Title"
    Seo.global.keywords = "Awesome, Words, Are, Awesome"
    Seo.global.luke = "Luke"
    industry = Industry.create
    industry.seo.luke = "Luke 2"
    industry.seo.luke = nil
    client = industry.clients.create
    client.seo.title = "Client Title"
    client.seo.keywords = "Awesome"
    client.seo.all.size.should.equal 3
    puts client.seo.all.inspect
    client.seo.luke.should.equal 'Luke'
  end


  it "should allow you to not include parent objects when grabbing all" do
    Seo.global.title = "SEO Title"

    industry = Industry.create
    industry.seo.title = "Industry Title"

    client = industry.clients.create
    client.seo.title = "Client Title"

    store = client.stores.create
    store.seo.title = "Store Title"

    store.seo.all(false).size.should.equal 1
    client.seo.all(false).size.should.equal 1
    industry.seo.all(false).size.should.equal 1
  end

  it "should work with four levels of nesting" do
    Seo.global.title = "SEO Title"
    industry = Industry.create
    client = industry.clients.create
    store = client.stores.create
    store.seo.title.should.equal "SEO Title"
  end

  describe "Type Conversion" do
    it "should store and retrieve Strings" do
      Seo.global.title = "Title"
      Seo.global.title.class.should.equal String
    end

    it "should store and retrieve Fixnums" do
      Seo.global.number = 42
      Seo.global.number.class.should.equal Fixnum
    end

    it "should store and retrieve Bignums" do
      Seo.global.number = 123456789101112131415161718123
      Seo.global.number.class.should.equal Bignum
      Seo.global.number.should.equal 123456789101112131415161718123
    end

    it "should store and retrieve Floats" do
      Seo.global.float = 1.2345678910
      Seo.global.float.class.should.equal Float
      Seo.global.float.should.equal 1.2345678910
    end

    it "should store and retrieve Symbols" do
      Seo.global.symbol = :symbol
      Seo.global.symbol.class.should.equal Symbol
      Seo.global.symbol.should.equal :symbol
    end

    it "should store and retrieve True" do
      Seo.global.true = true
      Seo.global.true.class.should.equal TrueClass
      Seo.global.true.should.equal true
    end

    it "should store and retrieve False" do
      Seo.global.false = false
      Seo.global.false.class.should.equal FalseClass
      Seo.global.false.should.equal false
    end

    it "should store and retrieve Time" do
      time = Time.now
      Seo.global.time = time
      Seo.global.time.class.should.equal Time
      Seo.global.time.to_s.should.equal time.to_s
    end

    it "should store and retrieve Dates" do
      date = Date.today
      Seo.global.date = date
      Seo.global.date.class.should.equal Date
      Seo.global.date.should.equal date
    end
    
    it "should store and retrieve DateTime" do
      datetime = DateTime.now
      Seo.global.datetime = datetime
      Seo.global.datetime.class.should.equal DateTime
      Seo.global.datetime.to_s.should.equal datetime.to_s
    end
  end
end
