<?php
declare(strict_types=1);

try {

  $pdo = new PDO('sqlite::/home/kurt/sqlite3-genealogy/roots-magic/roots-magic-09-06-2023.rmtree');

} catch(Exception $e) {

  echo "Exception thrown: " . $e->getMessage() . "\n";
  return;
}

var_dump($pdo);
return;

/*
  Use strnatcmp to implement RMNOCASE.
 */
$db->sqliteCreateCollation('RMNOCASE', 'strnatcmp'); 

return;

foreach ($db->query("SELECT col1 FROM test ORDER BY col1") as $row) {
  echo $row['col1'] . "\n";
}
echo "\n";
foreach ($db->query("SELECT col1 FROM test ORDER BY col1 COLLATE NATURAL_CMP") as $row) {
  echo $row['col1'] . "\n";
}
?>
