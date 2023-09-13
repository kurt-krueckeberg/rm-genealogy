<?php
declare(strict_types=1);
namespace RootsMagic;

class FileMover {

   public function __construct()
   {
   }

   private function mkDirName(string $surname, string $given) : string
   {

       return "xyz";
   }

   private function cp(string $fileName, string $dir)
   {

   }

   public function __invoke(string $fileName, string $surname, string $given)
   {
      $dir = $this->mkDirName($surname, $given); 

      if (!is_dir($dir))
          mkdir($dir, 0777);

      if (!file_exists($dir . "/" . $fileName)) 
          $this->cp($fileName, $dir);
   }
}
