require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'



# Funktion för att prata med databasen
# Exempel på användning: db.execute('SELECT * FROM fruits')
def db
  return @db if @db

  @db = SQLite3::Database.new(DB_PATH)
  @db.results_as_hash = true

  return @db
end

# Routen /
get '/' do
    slim(:index)
end


