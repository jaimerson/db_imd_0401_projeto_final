require_relative 'setup'

namespace :db do
  task :setup do
    Sequel.connect(database_url) do |db|
      puts "Connecting to #{database_url}..."
      puts 'Creating tables...'
      db.run(File.read('db/queries/create_tables.sql'))
      puts 'Done!'
    end
  end

  task :setup_data do
    Sequel.connect(database_url) do |db|
      puts "Connecting to #{database_url}..."
      db.run(File.read('db/queries/insert_data.sql'))
      puts 'Done!'
    end
  end

  task :drop do
    Sequel.connect(database_url) do |db|
      puts "Connecting to #{database_url}..."
      puts 'Nuking tables...'
      db.run(File.read('db/queries/drop_tables.sql'))
      puts 'Done!'
    end
  end

  task reset: [:drop, :setup]
end
