<?php
declare(strict_types=1);

static $media_names = array( 1 => 'Image', 2 => 'File', 3 => 'Sound', 4 => 'Video');

static $col_names = array("MediaType", 'MediaPath', 'MediaFile', 'OwnerTypeDesc', 'OwnerName','MediaDate');

try {

//  $pdo = new PDO('sqlite:/home/kurt/sqlite3-genealogy/rm/rm8-09-06-2023.rmtree');
  $lite = new SQLite3('rm8-09-06-2023.rmtree');

} catch(Exception $e) {

  echo "Exception thrown: " . $e->getMessage() . "\n";
  return;
}

$lite->createCollation('RMNOCASE', 'strnatcmp');	

function fetch_media(SQLite3 $lite) : SQLite3Result
{
  $media_query = file_get_contents("new-media.sql");

  return $lite->query($media_query);
}
  
$result = fetch_media($lite);

while ($row = $result->fetchArray(SQLITE3_ASSOC)) {

    //display_row($row);
    print_r($row); 
    echo "----------------\n";
}

return;

