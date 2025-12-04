require 'sqlite3'
require_relative 'cat_seed'

DB_PATH = File.join(__dir__, 'todos.db')

db = SQLite3::Database.new(DB_PATH)

def seed!(db)
  puts 'Using db file: db/todos.db'
  puts 'Seeding categories via cat_seed...'
  CatSeed.seed!(db)
  puts 'Dropping old todo table...'
  drop_tables(db)
  puts 'Creating todo table...'
  create_tables(db)
  puts 'Populating todo table...'
  populate_tables(db)
  puts 'Done seeding the database!'
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS todos')
end

def create_tables(db)
  db.execute("
    CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      cat_id INTEGER NOT NULL,
      status BOOLEAN NOT NULL DEFAULT 'false',
      FOREIGN KEY (cat_id) REFERENCES cat(id)
    )
  ")
end

def populate_tables(db)
  db.execute("INSERT INTO todos (name, description, cat_id, status)
              VALUES ('Kop mjolk', '3 liter mellanmjölk, eko', 3, 'false')")
  db.execute("INSERT INTO todos (name, description, cat_id, status)
              VALUES ('Kop julgran', 'En rödgran', 3, 'false')")
  db.execute("INSERT INTO todos (name, description, cat_id, status)
              VALUES ('Pynta gran', 'Glöm inte lamporna i granen och tomten', 3, 'true')")
end

seed!(db)
