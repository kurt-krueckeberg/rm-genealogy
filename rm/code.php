<?php

// ALSBERMEYER, 
$regex = '/([A-ZÄÖÜ]+), (?:([A-ZÄÖÜ][a-zöäü]+) *){1,}-\d+/'; 

$regex = '/^OwnerName = ([A-ZÄÖÜ]+), (?:([^ ]+) *){1,}-\d+/'

// This is the sim[lest regex but it still misses a few lines
$regex = '/^OwnerName = ([A-ZÄÖÜü]+),([^-]+)-\d+/'; // <-- still misses some lines--why?

