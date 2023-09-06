WITH nam as
(
Select
	NameTable.NameID,
	NameTable.OwnerID AS 'RIN1',
	NameTable.Surname COLLATE NOCASE AS 'Surname',
	NameTable.Given COLLATE NOCASE AS 'Given',

	UPPER( Surname ) || 
		CASE Suffix WHEN '' THEN '' ELSE ' ' || Suffix END
		|| ', ' || 
		CASE Prefix WHEN '' THEN ''ELSE Prefix || ' ' END 
		|| Given || 
		CASE WHEN Nickname NOT LIKE '' THEN ' "' || Nickname || '"'ELSE '' END
		 || '-' || OwnerID
		AS PersonName , 
	NameTable.IsPrimary	 
FROM NameTable		 
)
,pers as(
Select RIN1, Surname, Given, PersonName
FROM nam
where IsPrimary = 1
)
,fam as
(
select FamilyID, RIN1, Surname, Given, PersonName
from FamilyTable f inner join pers
on f.FatherID = pers.RIN1
where f.FatherID > 0
UNION
select FamilyID, RIN1, Surname, Given, PersonName
from FamilyTable f inner join pers
on f.MotherID = pers.RIN1
where f.MotherID > 0
)
,ev as
(SELECT e.eventID, e.eventtype,
f.Name COLLATE NOCASE AS FactType,
UPPER(f.Abbrev) COLLATE NOCASE AS FactAbbrev,
e.OwnerID, e.OwnerType, 
case 
	when e.OwnerType = 0 then 'Person'
	when e.OwnerType = 1 then 'Family'
	else ''
end AS OwnerTypeN,
case 
	when e.OwnerType = 0 then pers.PersonName
	when e.OwnerType = 1 then fam.PersonName
	else ''
end AS Ownername,

e.FamilyID, 
e.PlaceID, e.SiteID, 
e.SortDate, 
e.IsPrimary, e.IsPrivate, 
e.Proof, e.Status, 
e.UTCModDate, 
CAST(e.Sentence AS TEXT) AS Sentence, 
CAST(e.Details AS TEXT) AS Details, 
CAST(e.Note AS TEXT) AS Note
 from EventTable e
INNER JOIN FactTypeTable f ON
         e.EventType = f.FactTypeID
LEFT OUTER JOIN pers
ON e.OwnerID = pers.RIN1
AND e.OwnerType = 0
LEFT OUTER JOIN fam
ON e.OwnerID = fam.FamilyID
AND e.OwnerType = 1
)
,ctePlace as(
Select p.PlaceID, 0 as PlaceDetailID, p.Name as PlaceName, '' as PlaceDetailName,
p.Name  as PlaceFullName,
p.Reverse  as PlaceRevFullName
FROM PlaceTable p 
WHERE p.PlaceType = 0
UNION
Select p.PlaceID, pd.PlaceID as PlaceDetailID, p.Name as PlaceName, pd.Name as PlaceDetailName,
p.Name || " - " || pd.Name as PlaceFullName,
p.Reverse || " - " || pd.Name as PlaceRevFullName
FROM PlaceTable p INNER JOIN PlaceTable pd
on p.PlaceID = pd.MasterID and pd.PlaceType = 2
WHERE p.PlaceType = 0
)
,cteTask as(
SELECT
	t.TaskID,
	CASE 
		WHEN t.TaskType = 2 THEN 'ToDo'
		WHEN t.TaskType = 3 THEN 'Correspondence'
		WHEN t.TaskType = 1 THEN 'Research Log'
	ELSE '' 	END as TaskType,
	CASE
		WHEN tl.OwnerType = 0 THEN 'Individual'
		WHEN tl.OwnerType = 1 THEN 'Family'
		WHEN tl.OwnerType = 2 THEN 'Event'
		WHEN tl.OwnerType = 5 THEN 'Place'
		WHEN tl.OwnerType = 7 THEN 'Alt. Name'
		WHEN tl.OwnerType = 14 THEN 'Place Detail'
		WHEN tl.OwnerType IS NULL THEN 'General'
		WHEN tl.OwnerType = 18 THEN 'Task Folder'
	ELSE '' 	END as OwnerType,
	CASE
		WHEN tl.OwnerType = 0 THEN pers.PersonName
		WHEN tl.OwnerType = 1 THEN fam.PersonName
		WHEN tl.OwnerType = 2 THEN ev.OwnerName || ": " || ev.Factabbrev
		WHEN tl.OwnerType = 5 THEN ctePlace.PlaceFullName
		WHEN tl.OwnerType = 7 THEN nam.PersonName
		WHEN tl.OwnerType = 14 THEN ctePlace.PlaceFullName
		WHEN tl.OwnerType IS NULL THEN 'General'
		WHEN tl.OwnerType = 18 THEN tg.TagName
	ELSE '' 	END as OwnerName,
	t.NAME COLLATE Nocase AS TaskName 
FROM 
TaskTable t 
LEFT OUTER JOIN TaskLinkTable tl
ON t.TaskID = tl.TaskID 
LEFT OUTER JOIN pers
ON tl.OwnerID = pers.RIN1
AND tl.OwnerType = 0
LEFT OUTER JOIN fam
ON tl.OwnerID = fam.FamilyID
AND tl.OwnerType = 1
LEFT OUTER JOIN ev
ON tl.OwnerID = ev.EventID
AND tl.OwnerType = 2
LEFT OUTER JOIN nam
ON tl.OwnerID = nam.NameID
AND tl.OwnerType = 7
LEFT OUTER JOIN ctePlace
ON tl.OwnerID = ctePlace.PlaceID
AND (tl.OwnerType = 5 OR tl.OwnerType = 14)
LEFT OUTER JOIN TagTable tg
ON tl.OwnerID = tg.TagValue
AND tg.TagType = 1
AND tl.OwnerType = 18
)
,cteCit as(
select c.CitationID, c.CitationName, cl.OwnerType, c.SourceID, cl.OwnerID, cl.Quality, 
CASE cl.OwnerType
	WHEN 0 THEN 'Person'
	WHEN 1 THEN 'Family'
	WHEN 2 THEN 'Fact'
	WHEN 6 THEN 'Task'
	WHEN 7 THEN 'Alternate Name'
ELSE 'Unknown'
END as OwnerTypeN, 
case 
	when cl.OwnerType = 0 then pers.PersonName
	when cl.OwnerType = 1 then fam.PersonName
	when cl.OwnerType = 7 then nam.PersonName
	when cl.OwnerType = 2 then ev.OwnerName || " : " || ev.FactAbbrev
	
	when cl.OwnerType = 6 then tk.OwnerName
	else ''
end AS OwnerName,
src.Name || " - " || c.CitationName as CitFullName
FROM CitationTable c INNER JOIN CitationLinkTable cl
ON c.CitationID = cl.CitationID
LEFT OUTER JOIN pers
ON cl.OwnerID = pers.RIN1
AND cl.OwnerType = 0
LEFT OUTER JOIN fam
ON cl.OwnerID = fam.FamilyID
AND cl.OwnerType = 1
LEFT OUTER JOIN ev
ON cl.OwnerID = ev.EventID
AND cl.OwnerType = 2
LEFT OUTER JOIN nam
ON cl.OwnerID = nam.NameID
AND cl.OwnerType = 7
LEFT OUTER JOIN cteTask tk
ON cl.OwnerID = tk.TaskID
AND cl.OwnerType = 6
LEFT OUTER JOIN SourceTable src
ON c.sourceid = src.SourceID
)

SELECT DISTINCT
	MM.MediaID , 
	MM.MediaType , 
	MM.MediaPath , 
	MM.MediaFile COLLATE NOCASE as MediaFile, 
	MM.URL , 
	'=HYPERLINK("' || MM.MediaPath || MM.MediaFile || '","Open")' AS HyperLink ,
	MM.Thumbnail , 
	ML.LinkID , 
	ML.MediaID , 
	ML.OwnerType , 
	CASE WHEN ML.OwnerType = 0 THEN 'Person'
	WHEN ML.OwnerType = 1 THEN 'Family'
	WHEN ML.OwnerType = 2 THEN 'Event'
	WHEN ML.OwnerType = 3 THEN 'Source'
	WHEN ML.OwnerType = 4 THEN 'Citation'
	WHEN ML.OwnerType = 5 THEN 'Place'
	WHEN ML.OwnerType = 6 THEN 'Task'
	WHEN ML.OwnerType = 7 THEN 'Alt. Name'
	WHEN ML.OwnerType = 14 THEN 'Place Detail'
	ELSE '' END as OwnerTypeDesc,
	ML.OwnerID , 
	CASE WHEN ML.OwnerType = 0 THEN pers.PersonName
	WHEN ML.OwnerType = 1 THEN fam.PersonName
	WHEN ML.OwnerType = 2 THEN ev.OwnerName || ": " || ev.Factabbrev
	WHEN ML.OwnerType = 3 THEN SourceTable.Name
	WHEN ML.OwnerType = 4 THEN cteCit.OwnerName || " citing " || cteCit.CitFullName
	WHEN ML.OwnerType = 5 THEN ctePlace.PlaceName
	WHEN ML.OwnerType = 14 THEN ctePlace.PlaceName || " - " || ctePlace.PlaceDetailName
	WHEN ML.OwnerType = 6 THEN cteTask.TaskType || " - " || cteTask.TaskName
	WHEN ML.OwnerType = 7 THEN nam.PersonName
	ELSE '' END as OwnerName,
	
	ML.IsPrimary , 
	ML.Include1 as Scrpbk, 
	ML.Include2 , 
	ML.Include3 , 
	ML.Include4 , 
	ML.SortOrder , 
	ML.RectLeft , 
	ML.RectTop , 
	ML.RectRight , 
	ML.RectBottom , 
	ML.Comments , 
	MM.Caption COLLATE NOCASE , 
	MM.RefNumber COLLATE NOCASE , 
	CASE SUBSTR( MM.date
, 
      1 , 
      1 ) 
        WHEN 'Q' THEN MM.date 
        WHEN 'T' THEN Substr( MM.date , 
        2 , 
        20 ) 
        WHEN 'D' THEN CASE Substr( MM.date , 
        2 , 
        1 ) 
          WHEN 'A' THEN 'aft ' 
          WHEN 'B' THEN 'bef ' 
          WHEN 'F' THEN 'from ' 
          WHEN 'I' THEN 'since ' 
          WHEN 'R' THEN 'bet ' 
          WHEN 'S' THEN 'from ' 
          WHEN 'T' THEN 'to ' 
          WHEN 'U' THEN 'until ' 
          WHEN 'Y' THEN 'by ' 
          ELSE '' 
        END || CASE Substr( MM.date , 
        13 , 
        1 ) 
          WHEN 'A' THEN 'abt ' 
          WHEN 'C' THEN 'ca ' 
          WHEN 'E' THEN 'est ' 
          WHEN 'L' THEN 'calc ' 
          WHEN 'S' THEN 'say ' 
          WHEN '6' THEN 'cert ' 
          WHEN '5' THEN 'prob ' 
          WHEN '4' THEN 'poss ' 
          WHEN '3' THEN 'lkly ' 
          WHEN '2' THEN 'appar ' 
          WHEN '1' THEN 'prhps ' 
          WHEN '?' THEN 'maybe ' 
          ELSE '' 
        END || CASE 
          WHEN Substr( MM.date , 
          3 , 
          1 ) = '-' THEN 'BC' 
          ELSE '' 
        END || CASE 
          WHEN Substr( MM.date , 
          4 , 
          4 ) = '0000' THEN '' 
          ELSE Substr( MM.date , 
          4 , 
          4 ) 
        END || CASE 
          WHEN Substr( MM.date , 
          12 , 
          1 ) = '/' THEN '/' || ( 
            1 + Substr( MM.date , 
            3 , 
            5 ) 
          ) 
          ELSE '' 
        END || CASE 
          WHEN Substr( MM.date , 
          8 , 
          2 ) = '00' AND ( 
            Substr( MM.date , 
            4 , 
            4 ) <> '0000' AND Substr( MM.date , 
            10 , 
            2 ) <> '00' 
          ) THEN '-??' 
          WHEN Substr( MM.date , 
          8 , 
          2 ) = '00' AND ( 
            Substr( MM.date , 
            4 , 
            4 ) <> '0000' AND Substr( MM.date , 
            10 , 
            2 ) == '00' 
          ) THEN '' 
          WHEN Substr( MM.date , 
          8 , 
          2 ) = '00' THEN '' 
          ELSE '-' || Substr( MM.date , 
          8 , 
          2 ) 
        END || Coalesce( Nullif( '-' || Substr( MM.date , 
        10 , 
        2 ) , 
        '-00' ) , 
        '' ) || CASE Substr( MM.date , 
        2 , 
        1 ) 
          WHEN 'R' THEN ' and ' 
          WHEN 'S' THEN ' to ' 
          WHEN 'O' THEN ' or ' 
          WHEN '-' THEN ' - ' 
          ELSE '' 
        END || CASE Substr( MM.date , 
        24 , 
        1 ) 
          WHEN 'A' THEN 'abt ' 
          WHEN 'E' THEN 'est ' 
          WHEN 'L' THEN 'calc ' 
          WHEN 'C' THEN 'ca ' 
          WHEN 'S' THEN 'say ' 
          WHEN '6' THEN 'cert ' 
          WHEN '5' THEN 'prob ' 
          WHEN '4' THEN 'poss ' 
          WHEN '3' THEN 'lkly ' 
          WHEN '2' THEN 'appar ' 
          WHEN '1' THEN 'prhps ' 
          WHEN '?' THEN 'maybe ' 
          ELSE '' 
        END || CASE 
          WHEN Substr( MM.date , 
          14 , 
          1 ) = '-' THEN 'BC' 
          ELSE '' 
        END || CASE 
          WHEN Substr( MM.date , 
          15 , 
          4 ) = '0000' THEN '' 
          ELSE Substr( MM.date , 
          15 , 
          4 ) 
        END || CASE 
          WHEN Substr( MM.date , 
          23 , 
          1 ) = '/' THEN '/' || ( 
            1 + Substr( MM.date , 
            14 , 
            5 ) 
          ) 
          ELSE '' 
        END || CASE 
          WHEN Substr( MM.date , 
          19 , 
          2 ) = '00' AND ( 
            Substr( MM.date , 
            15 , 
            4 ) <> '0000' AND Substr( MM.date , 
            21 , 
            2 ) <> '00' 
          ) THEN '-??' 
          WHEN Substr( MM.date , 
          19 , 
          2 ) = '00' AND ( 
            Substr( MM.date , 
            15 , 
            4 ) <> '0000' AND Substr( MM.date , 
            21 , 
            2 ) == '00' 
          ) THEN '' 
          WHEN Substr( MM.date , 
          19 , 
          2 ) = '00' THEN '' 
          ELSE '-' || Substr( MM.date , 
          19 , 
          2 ) 
        END || Coalesce( Nullif( '-' || Substr( MM.date , 
        21 , 
        2 ) , 
        '-00' ) , 
        '' ) 
        ELSE '' 
      END AS MediaDate, 
	MM.SortDate , 
	CAST( MM.Description AS TEXT ) AS Description
FROM 
	MultiMediaTable AS MM LEFT JOIN 
	MediaLinkTable AS ML 
ON MM.MediaID = ML.MediaID
LEFT JOIN pers 
on ml.OwnerId = pers.RIN1 and ml.OwnerType = 0
LEFT JOIN fam
on ml.OwnerId = fam.FamilyID and ml.OwnerType = 1
LEFT JOIN ev 
on ml.OwnerId = ev.EventID and ml.OwnerType = 2
LEFT JOIN SourceTable
on ml.OwnerId = SourceTable.SourceID and ml.OwnerType = 3
LEFT JOIN cteCit 
on ml.OwnerId = cteCit.CitationID and ml.OwnerType = 4
LEFT JOIN ctePlace 
on ml.OwnerId = ctePlace.PlaceID and (ml.OwnerType = 5 or ml.OwnerType = 14)
LEFT JOIN cteTask 
on ml.OwnerId = cteTask.TaskID and ml.OwnerType = 6
LEFT JOIN nam
on ml.OwnerId = nam.NameID  and ml.OwnerType = 7
order by mediapath,mediafile,ownername
