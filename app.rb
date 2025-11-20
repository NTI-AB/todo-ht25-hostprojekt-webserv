require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'

# Show the todo list on the start page
get '/' do
  db = SQLite3::Database.new('db/todos.db')
  db.results_as_hash = true
  @todos = db.execute('SELECT * FROM todos ORDER BY id DESC')

  slim(:"index")

end