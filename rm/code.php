<?php
declare(strict_types=1);
use RootsMagic\FileReader;

include 'vendor/autoload.php';

/*
 This misses lines where there is no surname.
 How can they have happened?
 */


//--$regex = '/^OwnerName = ([^,]+),([^-]+)-\d+/';

$functor = new Functor($regex);

$file = new FileReader('output.txt');

$regex = '/([^,]+),([^-]+)-\d+/';

foreach ($file as $no => $line) {

  if (strcmp(substr($line, 0, 8), "MediaFile") === 0) 

    $image = substr($line, 13);
  
  else if ((strcmp(substr($line, 0, 9), "OwnerName") {

    // choose substring where the surname begins   
    $x = substr($line, 13);

    if (preg_match($regex, $line, $matches) !== 1)
  }
}
