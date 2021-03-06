require 'erb'
require_relative 'setup'
require_relative 'lib/parlamento'

namespace :data do
  task :fetch_all do
    parlamento = Parlamento.new
    parlamento.public_methods(false).each { |m| parlamento.send(m) }
  end

  task :fetch_deputados do
    parlamento = Parlamento.new
    parlamento.deputados
  end

end

namespace :db do
  task :setup do
    Sequel.connect(database_url) do |db|
      puts "Connecting to #{database_url}..."

      %w[tables functions views].each do |resource|
        puts "Creating #{resource}..."
        query = ERB.new(File.read("db/queries/create_#{resource}.sql")).result(binding)
        puts query
        db.run(query)
      end

      puts 'Done!'
    end
  end

  task setup_data: ['data:fetch_all'] do
    Sequel.connect(database_url) do |db|
      puts "Connecting to #{database_url}..."
      query = ERB.new(File.read('db/queries/insert_data.sql')).result(binding)
      puts query
      db.run(query)
      puts 'Done!'
    end
  end

  task :drop do
    Sequel.connect(database_url) do |db|
      puts "Connecting to #{database_url}..."
      puts 'Nuking tables...'
      db.run(File.read('db/queries/drop_tables.sql'))
      puts 'Nuking functions...'
      db.run(File.read('db/queries/drop_functions.sql'))
      puts 'Done!'
    end
  end

  task :dump do
    filepath = File.expand_path(File.join(__dir__, 'db', 'all.sql'))
    `pg_dump --no-security-labels --no-owner -Fp -x --inserts -d #{database_url} -f #{filepath}`
  end

  task reset: [:drop, :setup]
end
