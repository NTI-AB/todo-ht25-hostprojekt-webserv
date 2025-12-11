require 'sqlite3'

module CatSeed
  DB_PATH = ENV['DB_PATH'] || File.join(__dir__, 'todos.db')

  def self.seed!(db = SQLite3::Database.new(DB_PATH))
    puts 'Using db file: db/todos.db'
    puts 'Dropping old cat table...'
    drop_tables(db)
    puts 'Creating cat table...'
    create_tables(db)
    puts 'Populating cat table...'
    populate_tables(db)
    puts 'Done seeding categories!'
  end

  def self.drop_tables(db)
    db.execute('DROP TABLE IF EXISTS cat')
  end

  def self.create_tables(db)
    db.execute("
      CREATE TABLE cat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ")
  end

  def self.populate_tables(db)
    db.execute("INSERT INTO cat (id, name) VALUES (0, 'No category')")
    db.execute("INSERT INTO cat (name) VALUES ('Work')")
    db.execute("INSERT INTO cat (name) VALUES ('Shopping')")
    db.execute("INSERT INTO cat (name) VALUES ('Personal')")
  end
end

CatSeed.seed! if __FILE__ == $PROGRAM_NAME
