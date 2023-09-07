<?php
declare(strict_types=1);
namespace RootsMagic;

class Config {

   private \SimpleXMLElement $xml;

   public readonly string $file_name;

   public function __construct(string $fname)
   {   
      $this->xml = simplexml_load_file($fname);

      $this->base_url = (string) $this->xml->file_name;
   }

}
