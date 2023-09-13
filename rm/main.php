<?php
declare(strict_types=1);
use RootsMagic\FileReader;

include 'vendor/autoload.php';

$file = new FileReader('output.txt');

$image = '';

function process(string $imageFile, string $namePart)
{
   $comma_pos = strpos($namePart, ',');

   $surname = substr($namePart, 0, $comma_pos);

   // + 2 enables us to skip over ", "
   $givenNames = substr($namePart, $comma_pos + 2); 

   $givenNames = substr($givenNames, 0, strpos($givenNames, "-"));

  // Todo: mv $imageFile to surname subdir, if not exists.
}

function (string $fileName, string $surname, string $givenNames)
{

}

class MediaBlockFunctor {


  private string   $media_file;
  private string $surname;
  private string $givenNames;
  private callable $functor;

  public __construct(callable $func)
  {
      $this->media_file = '';
      $this->functor = $func;
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

      $this->functor($this->media_file, $this->surname, $this->givenNames);
  }
}

locale_set_default('de_DE');

$processMedia = new MediaBlockFunctor();

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
