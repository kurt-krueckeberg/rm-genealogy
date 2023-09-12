<?php
declare(strict_types=1);

/*
 This misses lines where there is no surname.
 How can they have happened?
 */
class Functor {

  public function __invoke(array $matches)
  {

     if (preg_match($regex, $line, $matches) !== 1) 
       return;
 

  }
}

$regex = '/^OwnerName = ([^,]+),([^-]+)-\d+/'; 

$functor = new Functor();

$file = new SplFileObject();

foreach($file as $no =< $line) {

  if (preg_match($regex, $line, $matches) !== 1) 
     continue;
  
  $functor($matches);
}
