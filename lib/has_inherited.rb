module HasInheritable
  def self.included(base)
    base.extend ClassMethods
  end # self.included

  module ClassMethods
    def is_inheritable(*name)
      attr = name.shift || :global
      assoc = "_#{attr}"
        
      named_scope assoc.to_sym,
          :conditions => 'inheritable_id IS NULL AND inheritable_type IS NULL'

      (class << self; self; end).instance_eval do
        define_method attr do
          instance_variable_get(:"@#{attr.to_s}") || instance_variable_set(:"@#{attr.to_s}", InheritAccessor.new(self, assoc.to_sym, nil))
        end
      end

      belongs_to :inheritable, :polymorphic => true
      include HasInheritable::InstanceMethods
    end

    def has_inheritable(*opts)
      options = opts.extract_options!
      attr = opts.shift || 'inheritable'
      assoc = "_#{attr}"
      class_name = options[:inherit_class] || 'Seo'

      has_many assoc.to_sym, :class_name => class_name, :as => :inheritable, :dependent => :destroy

      define_method attr do
      instance_variable_get(:"@#{attr.to_s}") || instance_variable_set(:"@#{attr.to_s}", InheritAccessor.new(self, assoc.to_sym, options[:from]))
      end
    end
  end # ClassMethods

  class InheritAccessor
    # In 1.9 I would use a BasicObject here. A conditional check wouldn't hurt.
    instance_methods.each {|m| undef_method m unless m.to_s =~ /(^__|send|inject)/}

    def initialize(owner, assoc, heritage)
      @owner = owner
      @assoc = @owner.send(assoc)
      if heritage.kind_of? Array
        @parent = heritage.first
        @parent_accessor = heritage.second
      else
        @parent = heritage
      end

      if @parent && @parent_accessor.nil?
        if @parent.kind_of? Class
          @parent_accessor = :global
        else
          @parent_accessor = :inheritable
        end
      end
    end

    def [](attribute)
      attr_value = find_attr(attribute).try(:value)
      if attr_value.nil? && has_parent?
        return parent.__send__(:[], attribute)
      else
        return attr_value
      end
    end

    def []=(attribute, value)
      attr = find_attr(attribute)
      if value.nil?
        attr.delete if attribute
      else
        if attr.nil?
          if @owner.respond_to?(:new_record?) && @owner.new_record?
            attr = @assoc.build(:name => attribute.to_s, :value => value)
          else
            attr = @assoc.create(:name => attribute.to_s, :value => value)
          end
        else
          attr.update_attributes(:value => value)
        end
      end
    end

    def all
      all_values = {}
      @assoc.all.each {|inherited| all_values[inherited.name.to_sym] = inherited.value}
      all_values
    end

    private 

    def parent
      if has_parent?
        parent = @parent.is_a?(Class) ? @parent : @owner.__send__(@parent)
        parent.__send__(@parent_accessor)
      else
        nil
      end
    end

    def find_attr(attr)
      @assoc.first(:conditions => ['name = ?', attr.to_s])
    end

    def has_parent?
      !! @parent
    end

    def method_missing(symbol, *args)
      name = symbol.to_s
      if name =~ /=$/
        self[name.gsub(/=$/, '')] = args.first
      else
        self[name]
      end
    end
  end

  module InstanceMethods
    def value
      case self[:value_type]
      when 'String'
        self[:value]
      when  'Fixnum', 'Bignum'
        Integer(self[:value])
      when 'Float'
        Float(self[:value])
      when 'Symbol'
        self[:value].to_sym
      when 'TrueClass'
        true
      when 'FalseClass'
        false
      when 'Time'
        Time.parse(self[:value])
      when 'Date'
        Date.parse(self[:value])
      when 'DateTime'
        DateTime.parse(self[:value])
      else
        self[:value]
      end
    end

    def value=(new_value)
      if new_value.nil?
        self[:value] = self.value_type = nil
      else
        new_type = new_value.class.to_s
        case new_type
        when 'Symbol'
          new_value = new_value.to_s
        when 'Fixnum', 'Float', 'Bignum', 'TrueClass', 'FalseClass'
          new_value = new_value.to_s
        when 'Time', 'Date', 'DateTime'
          new_value = new_value.to_s(:rfc822)
        end
        self[:value] = new_value
        self.value_type = new_type
      end
    end

  end
end

ActiveRecord::Base.send(:include, HasInheritable)
