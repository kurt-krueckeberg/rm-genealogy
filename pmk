#!/usr/bin/env php
<?php

if (count($argv) !== 2) {

  echo "Enter the input file name.\n";
  return;

}

$pre = substr($argv[1], 0, strpos($argv[1], "."));

$out = "$pre.html";

$cmd = "pandoc " . $argv[1] . " -c screen.css -s --metadata title='" . ucfirst($pre) ."' -t html -s -o $out";

exec($cmd);
