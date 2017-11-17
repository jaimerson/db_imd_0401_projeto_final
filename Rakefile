require 'erb'
require_relative 'setup'
require_relative 'lib/parlamento'

namespace :data do
  task :fetch_all do
    parlamento = Parlamento.new
    parlamento.detalhes_deputados
    parlamento.legislaturas
    parlamento.tipos_proposicao
    parlamento.blocos
  end
end

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
      query = ERB.new(File.read('db/queries/insert_data.sql')).result(binding)
      db.run(query)
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
