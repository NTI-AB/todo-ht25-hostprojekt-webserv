require 'sqlite3'
require 'fileutils'
require_relative 'cat_seed'

DEFAULT_DB_PATH = File.join(__dir__, 'todos.db')
DB_PATH = ENV['DB_PATH'] || DEFAULT_DB_PATH

db = SQLite3::Database.new(DB_PATH)

def using_default_db?
  File.expand_path(DB_PATH) == File.expand_path(DEFAULT_DB_PATH)
end

def delete_account_directories
  return unless using_default_db?

  account_dirs = Dir.children(__dir__).select do |entry|
    dir_path = File.join(__dir__, entry)
    File.directory?(dir_path) && entry.match?(/\A\d+\z/)
  end

  return if account_dirs.empty?

  puts 'Removing account directories...'
  account_dirs.each do |dir|
    FileUtils.rm_rf(File.join(__dir__, dir))
    puts " - Removed db/#{dir}"
  end
end

def seed!(db)
  puts "Using db file: #{DB_PATH}"
  puts 'Seeding categories via cat_seed...'
  CatSeed.seed!(db)
  puts 'Dropping old todo table...'
  drop_tables(db)
  delete_account_directories if __FILE__ == $PROGRAM_NAME && using_default_db?
  puts 'Creating todo and account tables...'
  create_tables(db)
  puts 'Populating todo table...'
  populate_tables(db)
  puts 'Done seeding the database!'
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS accounts')
  db.execute('DROP TABLE IF EXISTS todos')
end

def create_tables(db)
  db.execute("
    CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      email TEXT NOT NULL,
      password TEXT NOT NULL
    )
  ")
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
              VALUES ('Buy milk', '3 liters of organic semi-skimmed milk', 3, 'false')")
  db.execute("INSERT INTO todos (name, description, cat_id, status)
              VALUES ('Buy Christmas tree', 'A spruce tree', 3, 'false')")
  db.execute("INSERT INTO todos (name, description, cat_id, status)
              VALUES ('Decorate the tree', 'Do not forget the lights and the tree topper', 3, 'true')")
end

seed!(db)
