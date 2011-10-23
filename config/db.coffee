# Place your Database config here
# connect to mongodb
mongodb = require 'mongodb'
Db = mongodb.Db
Connection = mongodb.Connection
Server = mongodb.Server
HOST = 'localhost'
PORT = Connection.DEFAULT_PORT
DBNAME = 'location'
COLNAME = 'loc'
config = SS.config.db.mongo
global.M = new Db(config.database, new Server(config.host, config.port))
M.open (err, client) -> if err? console.error(err) else console.log ' >>>> database opened <<<< '
