<?php
declare(strict_types=1);
namespace RootsMagic;

class FileMover {

   public function __construct(string $srcDir)
   {
      $this->src_dir = $srcDir;
   }

   public function __invoke(string $fileName, string $surname, string $given)
   {
      $dir = $surname . ", " $given; 

      if (!is_dir($dir))
          mkdir($dir, 0777);

      $destName =  $dir . "/" . $fileName;
     
      if (!file_exists($destName))  {

          $fromName = $this->srcDir . "/" . $fileName;

          copy($fromName, $destName);
      } 
   }
}
