<?php
declare(strict_types=1);
use RootsMagic\{FileReader, FileMover, MediaExtractor};

include 'vendor/autoload.php';

locale_set_default('de_DE');

$media_file_processor = new MediaExtractor(new FileMover("~/d/genealogy/roots-magic-09-06-2023_media/"));

$file = new FileReader('output.txt');
/*
foreach ($file as $no => $line) {
 
     $media_file_processor($line);
}
*/
