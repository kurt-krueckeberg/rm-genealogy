<?php
declare(strict_types=1);
use RootsMagic\FileReader;

include 'vendor/autoload.php';

$file = new FileReader('output.txt');

$image = '';

class FileMover {

   public function __construct()
   {
   }

   private function mkDirName(string $surname, string $given) : string
   {

       return "xyz";
   }

   public function __invoke(string $fileName, string $surname, string $given)
   {
      $dir = $this->mkDirName($surname, $given): 

      if (!is_dir($dir)
          mkdir($dir, 0777);

      if (!file_exists($dir . "/" . $fileName)) 
          $this->cp($fileName, $dir);
   }
}

class MediaBlockFunctor {


  private string   $media_file;
  private string $surname;
  private string $givenNames;
  private callable $file_mover;

  public __construct(callable $func)
  {
      $this->media_file = '';
      $this->file_mover = $func;
  }

  private function create_person_name(string $nameStr)
  {
     $comma_pos = strpos($nameStr, ',');
 
     $surname = strtolower(substr($nameStr, 0, $comma_pos));
     
     $this->surname = ucfirst($surname);

     // + 2 enables us to skip over ", "
     $givenNames = substr($nameStr, $comma_pos + 2); 
 
     $this->givenNames = substr($givenNames, 0, strpos($givenNames, "-"));
  }

  public function __invoke(string $line)
  {
    if ($line[5] == 'F') {// 'MediaFile' test

     $this->media_file = substr($line, 13);
  
    // "OwnerName" test
    } else if ($line[5] == 'N') {

      // choose substring where the surname begins   
      $person_name = substr($line, 12);

      $this->create_person_name($namePart);  

      $this->file_mover($this->media_file, $this->surname, $this->givenNames);
  }
}

locale_set_default('de_DE');

$processMedia = new MediaBlockFunctor(new FileMover());

foreach ($file as $no => $line) 
     process($line);
/*
{

  if ($line[5] == 'F') {// 'MediaFile' test

    $image = substr($line, 13);
  
    // "OwnerName" test
  } else if ($line[5] == 'N') {

    // choose substring where the surname begins   
    $namePart = substr($line, 12);

    process($image, $namePart);  
  }
*/}
