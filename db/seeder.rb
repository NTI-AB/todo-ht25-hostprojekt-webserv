require 'sqlite3'

db = SQLite3::Database.new("todos.db")

def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute("DROP TABLE IF EXISTS todos")
end

def create_tables(db)
  db.execute("
    CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL, 
      description TEXT,
      type TEXT NOT NULL DEFAULT 'privat',
      status BOOLEAN NOT NULL DEFAULT 'false'
    )
  ")
end

def populate_tables(db)
  db.execute("INSERT INTO todos (name, description, type, status)
              VALUES ('Köp mjölk', '3 liter mellanmjölk, eko', 'privat', 'false')")
  db.execute("INSERT INTO todos (name, description, type, status)
              VALUES ('Köp julgran', 'En rödgran', 'privat', 'false')")
  db.execute("INSERT INTO todos (name, description, type, status)
              VALUES ('Pynta gran', 'Glöm inte lamporna i granen och tomten', 'privat', 'true')")
end

seed!(db)
