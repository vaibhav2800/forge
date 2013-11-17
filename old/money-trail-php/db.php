<?php
const DBFILE = './money-trail.db';

/** Create and return an SQLite3 object, creates the DB if missing. */
function get_db() {
  if (!file_exists(DBFILE)) {
    $db = new SQLite3(DBFILE, SQLITE3_OPEN_READWRITE | SQLITE3_OPEN_CREATE);
    $sql = file_get_contents('create-tables.sql');
    $db->exec($sql);
    $db->close();
  }

  $db = new SQLite3(DBFILE, SQLITE3_OPEN_READWRITE);
  $db->exec('PRAGMA foreign_keys = on;');
  return $db;
}
?>
