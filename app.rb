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

  def first_cat_id(db)
    db.get_first_value('SELECT id FROM cat ORDER BY id ASC LIMIT 1')
  end
end

# Show the todo list on the start page
get '/' do
  db = todos_db
  status_filter = params[:status].to_s
  cat_filter = params[:cat_id].to_s.strip
  @cats = db.execute('SELECT id, name FROM cat ORDER BY LOWER(name) ASC')

  query = 'SELECT todos.*, cat.name AS cat_name FROM todos JOIN cat ON cat.id = todos.cat_id'
  conditions = []
  values = []

  case status_filter
  when 'done'
    conditions << 'status = ?'
    values << 'true'
  when 'active'
    conditions << 'status != ?'
    values << 'true'
  end

  unless cat_filter.empty?
    conditions << 'todos.cat_id = ?'
    values << cat_filter.to_i
  end

  query += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
  query += ' ORDER BY id DESC'

  @todos = db.execute(query, values)
  @active_todos = @todos.select { |todo| todo['status'].to_s != 'true' }
  @filter_status = status_filter
  @filter_cat_id = cat_filter

  slim(:index)
end

post '/todos' do
  name = params[:name]
  description = params[:description]
  status = params[:status] == 'true' ? 'true' : 'false'
  db = todos_db
  cat_id = params[:cat_id].to_i
  cat_id = first_cat_id(db) if cat_id <= 0

  db.execute('INSERT INTO todos (name, description, cat_id, status) VALUES (?, ?, ?, ?)',
             [name, description, cat_id, status])

  redirect '/'
end

post '/cat' do
  name = params[:name]
  db = todos_db
  db.execute('INSERT INTO cat (name) VALUES (?)',
             [name])

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
  @cats = db.execute('SELECT id, name FROM cat ORDER BY LOWER(name) ASC')

  halt 404, 'Todo not found' unless @todo

  slim(:"todos/edit")
end

post '/todos/:id/update' do
  id = params[:id].to_i
  name = params[:name]
  description = params[:description]
  status = params[:status] == 'true' ? 'true' : 'false'
  db = todos_db
  cat_id = params[:cat_id].to_i
  cat_id = first_cat_id(db) if cat_id <= 0

  db.execute('UPDATE todos SET name = ?, description = ?, cat_id = ?, status = ? WHERE id = ?',
             [name, description, cat_id, status, id])

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
