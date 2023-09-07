<?php
declare(strict_types=1);

class Displayer {

    private static $media_names = array( 1 => 'Image', 2 => 'File', 3 => 'Sound', 4 => 'Video');

    private static $col_names = array("MediaType", 'MediaPath', 'MediaFile', 'OwnerTypeDesc', 'OwnerName','MediaDate');

    public function __invoke(array $ar) 
    {
        foreach(self::$col_names as $key => $attrib) {

          if ($key == 0)
             echo "MediaType = " . self::$media_names[$ar['MediaType']] . "\n"; 

          else 
             echo $attrib . " = " . $ar[$attrib] . "\n";
        }

        echo "------------------------\n";
    }
}

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
  
$result = fetch_media($lite);

$display = new Displayer();

while ($row = $result->fetchArray(SQLITE3_ASSOC))

    $display($row);

return;

