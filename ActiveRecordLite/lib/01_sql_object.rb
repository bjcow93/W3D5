require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.
class SQLObject

  def self.columns
    return @column_names unless @column_names.nil?

    @column_names = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL

      @column_names = @column_names[0].map do |column|
        column.to_sym
      end
  end

  def self.finalize!

    self.columns.each do |column|
      define_method(column) do
        self.attributes[column.to_sym]
      end

      define_method("#{column}=") do |value|
        self.attributes[column.to_sym] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(rows)
  end

  def self.parse_all(results)
    results.map {|result| self.new(result)}
  end

  def self.find(id)
    answer = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = #{id}
    SQL
    return nil if answer.empty?
    return self.new(answer.first)
  end

  def initialize(params = {})
    params.each do |attr_name,value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" if !self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values

  end

  def insert
    col_names = self.columns.join(",")
    values = self.attribute_values
    question_marks = (["?"] * values.length).join(",")
    p values

    
    DBConnection.execute(<<-SQL, *values)
    INSERT INTO
      #{self.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
