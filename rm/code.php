<?php
declare(strict_types=1);
use RootsMagic\FileReader;

/*
 This misses lines where there is no surname.
 How can they have happened?
 */
class Functor {

  public function __construct()
  {
  }

  public function __invoke(array $matches)
  {

     if (preg_match($regex, $line, $matches) !== 1) 
       return;
     
     echo "Surname, given: " . $matches[1] . ", " . $matches[2] . "\n";
  }
}

$regex = '/^OwnerName = ([^,]+),([^-]+)-\d+/'; 

$functor = new Functor();

$file = new FileReader('output.txt');

foreach($file as $no =< $line) {

  $functor($matches);
}
