require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'
require 'securerandom'

SESSION_SECRET_MIN_LENGTH = 64
session_secret = ENV['SESSION_SECRET']

if session_secret.nil? || session_secret.bytesize < SESSION_SECRET_MIN_LENGTH
  warn "SESSION_SECRET is missing or too short (#{session_secret&.bytesize || 0}); generating a temporary secret. Set SESSION_SECRET to at least #{SESSION_SECRET_MIN_LENGTH} bytes in production."
  session_secret = SecureRandom.hex(64)
end

enable :sessions
set :session_secret, session_secret

helpers do
  def todos_db
    db = SQLite3::Database.new('db/todos.db')
    db.results_as_hash = true
    db
  end

  def ensure_default_cat(db)
    db.execute('INSERT OR IGNORE INTO cat (id, name) VALUES (?, ?)', [0, 'ingen kategori'])
    db.execute('UPDATE cat SET name = ? WHERE id = ?', ['ingen kategori', 0])
  end

  def first_cat_id(db)
    db.get_first_value('SELECT id FROM cat ORDER BY id ASC LIMIT 1')
  end

  def current_user(db = nil)
    return @current_user if defined?(@current_user)
    return nil unless session[:account_id]

    db ||= todos_db
    @current_user = db.execute('SELECT id, username, email FROM accounts WHERE id = ?', session[:account_id]).first
  rescue SQLite3::SQLException
    @current_user = nil
  end

  def set_flash(type, message)
    session[:flash] = { type: type, message: message }
  end

  def flash_message
    session.delete(:flash)
  end
end

# Show the todo list on the start page
get '/' do
  db = todos_db
  @current_user = current_user(db)
  @flash = flash_message
  ensure_default_cat(db)
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
  ensure_default_cat(db)
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

post '/cat/:id/delete' do
  id = params[:id].to_i
  db = todos_db
  ensure_default_cat(db)

  redirect '/' if id <= 0

  db.execute('UPDATE todos SET cat_id = 0 WHERE cat_id = ?', id)
  db.execute('DELETE FROM cat WHERE id = ?', id)

  redirect '/'
end

post '/cat/delete' do
  id = params[:cat_id].to_i
  db = todos_db
  ensure_default_cat(db)

  redirect '/' if id <= 0

  db.execute('UPDATE todos SET cat_id = 0 WHERE cat_id = ?', id)
  db.execute('DELETE FROM cat WHERE id = ?', id)

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
  ensure_default_cat(db)
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
  ensure_default_cat(db)
  cat_id = params[:cat_id].to_i
  cat_id = first_cat_id(db) if cat_id <= 0

  db.execute('UPDATE todos SET name = ?, description = ?, cat_id = ?, status = ? WHERE id = ?',
             [name, description, cat_id, status, id])

  redirect '/'
end

post '/register' do
  username = params[:username].to_s.strip
  email = params[:email].to_s.strip.downcase
  password = params[:password].to_s
  db = todos_db

  if username.empty? || email.empty? || password.empty?
    set_flash('error', 'Fyll i alla fält för att registrera dig.')
    redirect '/'
  end

  existing = db.get_first_value('SELECT id FROM accounts WHERE email = ?', email)
  if existing
    set_flash('error', 'E-postadressen används redan.')
    redirect '/'
  end

  password_hash = BCrypt::Password.create(password)
  db.execute('INSERT INTO accounts (username, email, password) VALUES (?, ?, ?)',
             [username, email, password_hash])

  session[:account_id] = db.last_insert_row_id
  set_flash('success', 'Registrering lyckades, du är inloggad.')
  redirect '/'
end

post '/login' do
  email = params[:email].to_s.strip.downcase
  password = params[:password].to_s
  db = todos_db

  account = db.execute('SELECT * FROM accounts WHERE email = ?', email).first

  authenticated = false

  if account && account['password']
    begin
      authenticated = BCrypt::Password.new(account['password']) == password
    rescue BCrypt::Errors::InvalidHash
      authenticated = false
    end
  end

  if account && authenticated
    session[:account_id] = account['id']
    set_flash('success', 'Inloggning lyckades.')
  else
    set_flash('error', 'Fel e-post eller lösenord.')
  end

  redirect '/'
end

post '/logout' do
  session.delete(:account_id)
  set_flash('success', 'Du är utloggad.')
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
