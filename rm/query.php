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

function fetch_media(SQLite3 $lite) : SQLite3Result
{
  $media_query = file_get_contents("media.sql");

  return $lite->query($media_query);
}

function fetch_factTypes(SQLite3 $lite) : array
{
  static $query = "select FactTypeID as id, Name from FactTypeTable";

  $result = $lite->query($query);

  $output = array();

  while($row = $result->fetchArray(SQLITE3_ASSOC))
      
     $output[$row['id']] = $row['Name'];

  return $output;
}

$factTypes = fetch_factTypes($lite);

$media_result = fetch_media($lite);

$cols = array("MediaType", 'MediaPath', 'MediaFile', 'OwnerTypeDesc', 'OwnerName','MediaDate');

while($media_row = $media_result->fetchArray(SQLITE3_ASSOC)) {

     /*
     foreach($cols as $attrib) {
              
        
       echo $attrib . " = " . $media_row[$attrib] . "\n";
     }
     
     //  todo: Use the Fact/Event Type id to look up the FactType Name
   
     $factType['MediaType']
     */
     print_r($media_row);
     echo "------------------------\n";
}

return;