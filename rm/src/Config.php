<?php
declare(strict_types=1);
namespace RootsMagic;

class Config {

   private \SimpleXMLElement $xml;

   public readonly string $filename;

   public function __construct(string $fname)
   {   
      $this->xml = simplexml_load_file($fname);

      $this->filename = (string) $this->xml->file_name;
   }

}
