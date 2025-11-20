require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'





# Routen /
get '/' do
    slim(:index)
end


get '/' do
  query = params[:q]
  db = SQLite3::Database.new("db/fruits.db")
 
  #gör de det till [{},{},{}]
  db.results_as_hash = true
  if query && !query.empty?
    @data = db.execute("SELECT * FROM fruits WHERE name LIKE ?", "%#{query}%")
  else
    @data = db.execute("SELECT * FROM fruits")
  end

  p @data

  slim(:"index")

end