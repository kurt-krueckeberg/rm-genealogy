<?php
declare(strict_types=1);

try {

//  $pdo = new PDO('sqlite:/home/kurt/sqlite3-genealogy/rm/rm8-09-06-2023.rmtree');
  $lite = new SQLite3('rm8-09-06-2023.rmtree');

} catch(Exception $e) {

  echo "Exception thrown: " . $e->getMessage() . "\n";
  return;
}

$lite->createCollation('RMNOCASE', 'strnatcmp');	

$q = file_get_contents("media.sql");

$returned_set = $lite->query($q);

$cols = array("MediaType", 'MediaPath', 'MediaFile', 'OwnerTypeDesc', 'OwnerName','MediaDate');

while($result = $returned_set->fetchArray(SQLITE3_ASSOC)) {

     foreach($cols as $attrib) {
    
       echo $attrib . " = " . $result[$attrib] . "\n";
     }
     
     echo "------------------------\n";
}

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
