require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'

helpers do
  def todos_db
    db = SQLite3::Database.new('db/todos.db')
    db.results_as_hash = true
    db
  end
end

# Show the todo list on the start page
get '/' do
  db = todos_db
  @todos = db.execute('SELECT * FROM todos ORDER BY id DESC')
  @active_todos = @todos.select { |todo| todo['status'].to_s != 'true' }

  slim(:index)
end

post '/todos' do
  name = params[:name]
  description = params[:description]
  type = params[:type].to_s.strip.empty? ? 'privat' : params[:type]
  status = params[:status] == 'true' ? 'true' : 'false'

  db = SQLite3::Database.new('db/todos.db')
  db.execute('INSERT INTO todos (name, description, type, status) VALUES (?, ?, ?, ?)',
             [name, description, type, status])

  redirect '/'
end

post '/todos/:id/delete' do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/todos.db')
  db.execute('DELETE FROM todos WHERE id = ?', id)

  redirect '/'
end

get '/todos/:id/edit' do
  id = params[:id].to_i
  db = todos_db
  @todo = db.execute('SELECT * FROM todos WHERE id = ?', id).first

  halt 404, 'Todo not found' unless @todo

  slim(:"todos/edit")
end

post '/todos/:id/update' do
  id = params[:id].to_i
  name = params[:name]
  description = params[:description]
  type = params[:type].to_s.strip.empty? ? 'privat' : params[:type]
  status = params[:status] == 'true' ? 'true' : 'false'

  db = SQLite3::Database.new('db/todos.db')
  db.execute('UPDATE todos SET name = ?, description = ?, type = ?, status = ? WHERE id = ?',
             [name, description, type, status, id])

  redirect '/'
end

post '/todos/:id/toggle' do
  id = params[:id].to_i
  db = todos_db
  todo = db.execute('SELECT status FROM todos WHERE id = ?', id).first

  halt 404, 'Todo not found' unless todo

  new_status = todo['status'].to_s == 'true' ? 'false' : 'true'
  db.execute('UPDATE todos SET status = ? WHERE id = ?', [new_status, id])

  redirect '/'
end
