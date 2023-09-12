<?php
declare(strict_types=1);
use RootsMagic\FileReader;

include 'vendor/autoload.php';

/*
 This misses lines where there is no surname.
 How can they have happened?
 */

class Functor
{

  private readonly string $regex;
  private string $currentImage;
  
  public function __construct(string $regularEx)
  {
    $this->regex = $regularEx;
  }

  public function __invoke(string $line)
  {
    if (strcmp(substr($line, 0, 8), "MediaFile") === 0) {

      $this->currentImage = substr($line, 13);
      return;
    }
       
    if (preg_match($this->regex, $line, $matches) !== 1)
      return;

    echo "Surname, given: " . $matches[1] . ", " . $matches[2] . "\n";

    $this->currentImage = '';
  }
}

$regex = '/^OwnerName = ([^,]+),([^-]+)-\d+/';

$functor = new Functor($regex);

$file = new FileReader('output.txt');

foreach ($file as $no => $line) {

  $functor($line);
}
