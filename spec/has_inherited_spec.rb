require 'spec_helper'


class Seo < ActiveRecord::Base
  is_inheritable :global
end

class Industry < ActiveRecord::Base
  has_inheritable :seo, :from => Seo
end

describe "HasInherited" do

  before do
    ActiveRecord::Base.logger = Logger.new('test.log')
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
end
