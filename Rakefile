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
    parlamento.despesas
    parlamento.detalhes_proposicoes
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
      puts 'Creating tables...'
      db.run(File.read('db/queries/create_tables.sql'))
      puts 'Creating functions...'
      db.run(File.read('db/queries/functions.sql'))
      puts 'Done!'
    end
  end

  task :setup_data do
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
      puts 'Done!'
    end
  end

  task :dump do
    filepath = File.expand_path(File.join(__dir__, 'db', 'all.sql'))
    `pg_dump --no-security-labels --no-owner -Fp -x --inserts -d #{database_url} -f #{filepath}`
  end

  task reset: [:drop, :setup]
end
