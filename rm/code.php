<?php
declare(strict_types=1);

class ResultIterator implements \Iterator {

  private SQLite3Result $result;

  private $current = array();

  private int $index;

  public function __construct(SQLite3Result &$result_in)
  {
     $this->result = $result_in;

     $this->current = false;

     $this->rewind();
  }

  public function current(): mixed
  {
     return $this->current;
  }
  
  public function key(): mixed
  {
     return $this->index;
  }

  private function fetch_next()
  {
     return$this->result->fetchArray(SQLITE3_ASSOC);
  }
  
  public function next(): void
  {
     $this->current = $this->fetch_next();

     if ($this->valid())

         ++$this->index;
  }
  
  public function rewind(): void
  {
   
    $this->current = $this->fetch_next();
    $this->index = 0;
  }
   
  public function valid(): bool
  {
     return ($this->current === false) ? false : true; 
  }
}

class ResultDisplayer {

static $media_names = array( 1 => 'Image', 2 => 'File', 3 => 'Sound', 4 => 'Video');

static $col_names = array("MediaType", 'MediaPath', 'MediaFile', 'OwnerTypeDesc', 'OwnerName','MediaDate');

    public function __invoke($ar)  //SQLite3Result $result)
    {
        $row = array();
           
        foreach(self::$col_names as $attrib)
                
        echo "$attrib = {$ar[$attrib]}\n";

        echo "MediaType Name = " . self::$media_names[$ar['MediaType']]; 
        
        echo "------------------------\n";
    }
}