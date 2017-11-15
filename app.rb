require_relative 'setup'
require 'sinatra'

class Report
  class << self
    class Item < Struct.new(:identifier, :query, :description)
      def execute(connection)
        connection.fetch(query).map(&:itself)
      end
    end

    def items
      @items ||= []
    end

    def item(identifier, description: identifier)
      query = File.read("db/queries/#{identifier}.sql")
      self.items ||= []
      self.items << Item.new(identifier, query, description)
    end
  end

  # item 'unsold_products', description: <<-DESCRIPTION
  # Selecione todos os produtos que nunca foram vendidos. Use EXISTS para tal.
  # DESCRIPTION

  attr_reader :connection

  def initialize(connection)
    @connection = connection
  end

  def each_item
    self.class.items.each do |item|
      yield item.description, item.execute(connection), item.query
    end
  end
end

get '/' do
  connection = Sequel.connect(database_url)
  report = Report.new(connection)
  erb :index, locals: { report: report }
end
