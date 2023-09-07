/* facts and citations - can produce list of unproven or un-cited facts - RM7 version
	by Pat Jones
*/
with cit as
 (select c.CitationID, cl.OwnerType, c.SourceID, cl.OwnerID, cl.Quality, cl.IsPrivate, QUOTE(c.actualtext) AS CitTxt, QUOTE(c.comments) AS CitComment, 
 c.RefNumber, cl.Flags, s.SourceID, s.Name as SourceName,
  -- CitationTable FIELDS parsed out from XML in a blob
    REPLACE(                                                                                                
        REPLACE(
         REPLACE(
          REPLACE(
           REPLACE(
			REPLACE(
				REPLACE(
					REPLACE(CAST(c.Fields AS TEXT), '</Name>', ':'||CAST (X'09' AS TEXT)),
				'<Field><Name>', ''),
			'</Value>',''),
          '<Value>',''),
        '<Value/>',''),
       '</Field>',CAST (X'0D' AS TEXT)),
	  '<Root><Fields>',''),
	'</Fields></Root>','')
	AS 'CitationFields'
FROM CitationTable  c INNER JOIN CitationLinkTable cl
ON c.CitationID = cl.CitationID
 LEFT OUTER JOIN SourceTable s ON c.SourceID = s.SourceID
 WHERE cl.OwnerType = 2)
,pers as
(Select
         NameTable.OwnerID AS 'RIN1',
         NameTable.Surname COLLATE NOCASE AS 'Surname',
         NameTable.Given  COLLATE NOCASE AS 'Given'
FROM NameTable		 
where NameTable.IsPrimary = 1
)
,fam as
(
select FamilyID, RIN1, Surname, Given
from FamilyTable f inner join pers
on f.FatherID = pers.RIN1
where f.FatherID > 0
UNION
select FamilyID, RIN1, Surname, Given
from FamilyTable f inner join pers
on f.MotherID = pers.RIN1
where f.MotherID > 0
)
,ev as(
SELECT e.eventID, e.eventtype,
f.Name COLLATE NOCASE AS FactType,
e.OwnerType, 
case 
	when e.OwnerType = 0 then 'Person'
	when e.OwnerType = 1 then 'Family'
	else ''
end AS OwnerTypeN,
e.OwnerID, e.FamilyID, 
-- Convert Fact dates to readable form
      CASE Substr( e.Date,1 ,1 ) 
        WHEN 'Q' THEN e.Date 
        WHEN 'T' THEN Substr( e.Date ,2 ,20 ) 
        WHEN 'D' THEN CASE Substr( e.Date ,2 ,1 ) 
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
        END || CASE Substr( e.Date ,13 ,1 ) 
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
          WHEN Substr( e.Date ,3 ,1 ) = '-' THEN 'BC' 
          ELSE '' 
        END || CASE 
          WHEN Substr( e.Date ,4 ,4 ) = '0000' THEN '' 
          ELSE Substr( e.Date ,4 ,4 ) 
        END || CASE 
          WHEN Substr( e.Date ,12 ,1 ) = '/' THEN '/' || (1 + Substr( e.Date ,3 ,5 ) ) 
          ELSE '' 
        END || CASE 
          WHEN Substr( e.Date ,8 ,2 ) = '00' AND (Substr( e.Date ,4 ,4 ) <> '0000' AND Substr( e.Date ,10 ,2 ) <> '00') THEN '-??' 
          WHEN Substr( e.Date ,8 ,2 ) = '00' AND ( Substr( e.Date , 4 , 4 ) <> '0000' AND Substr( e.Date , 10 , 2 ) == '00' ) THEN '' 
		WHEN Substr( e.Date , 8 , 2 ) = '00' THEN '' 
		ELSE '-' || Substr( e.Date , 8 , 2 ) 
		END || Coalesce( Nullif( '-' || Substr( e.Date , 10 , 2 ) , '-00' ) , '' ) || CASE Substr( e.Date , 2 , 1 ) 
		WHEN 'R' THEN ' and ' 
		WHEN 'S' THEN ' to ' 
		WHEN 'O' THEN ' or ' 
		WHEN '-' THEN ' - ' 
		ELSE '' 
		END || CASE Substr( e.Date , 24 , 1 ) 
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
		WHEN Substr( e.Date , 14 , 1 ) = '-' THEN 'BC' 
		ELSE '' 
		END || CASE 
		WHEN Substr( e.Date , 15 , 4 ) = '0000' THEN '' 
		ELSE Substr( e.Date , 15 , 4 ) 
		END || CASE 
		WHEN Substr( e.Date , 23 , 1 ) = '/' THEN '/' || ( 1 + Substr( e.Date , 14 , 5 ) ) 
		ELSE '' 
		END || CASE 
		WHEN Substr( e.Date , 19 , 2 ) = '00' AND ( Substr( e.Date , 15 , 4 ) <> '0000' AND Substr( e.Date , 21 , 2 ) <> '00' ) THEN '-??' 
		WHEN Substr( e.Date , 19 , 2 ) = '00' AND ( Substr( e.Date , 15 , 4 ) <> '0000' AND Substr( e.Date , 21 , 2 ) == '00' ) THEN '' 
		WHEN Substr( e.Date , 19 , 2 ) = '00' THEN '' ELSE '-' || Substr( e.Date , 19 , 2 ) 
		END || Coalesce( Nullif( '-' || Substr( e.Date , 21 , 2 ) , '-00' ) , '' ) 
		ELSE '' 
      END AS 'EventDate' , 
e.PlaceID, e.SiteID, e.SortDate, e.IsPrimary, e.IsPrivate, 
e.Proof, e.Status, e.UTCModDate, e.Sentence, e.Details, e.Note
 from EventTable e
INNER JOIN FactTypeTable f ON
         e.EventType = f.FactTypeID
) 
,pl as
(
/* Place CTE */
/* First without detail to get all places so have a non-detail version for all */
Select p.PlaceID, 0 as PlaceDetailID, p.Name COLLATE NOCASE AS PlaceName, '' as PlaceDetailName
FROM PlaceTable p 
WHERE p.PlaceType = 0
UNION
/* Then with detail */
Select p.PlaceID, pd.PlaceID as PlaceDetailID, p.Name COLLATE NOCASE AS PlaceName, pd.Name COLLATE NOCASE AS PlaceDetailName
FROM PlaceTable p INNER JOIN PlaceTable pd
on p.PlaceID = pd.MasterID and pd.PlaceType = 2
WHERE p.PlaceType = 0

)
/* finally the main query */
select 
EventID, 
EventType,
FactType,
ev.OwnerType,
ev.OwnerTypeN, 
case when ev.OwnerType = 1 THEN fam.Surname
	ELSE pers.Surname
	END as Surname,
case when ev.OwnerType = 1 THEN fam.Given
	ELSE pers.Given
	END as Given,
case when ev.OwnerType = 1 THEN fam.RIN1
	ELSE pers.RIN1
	END as RIN1,
ev.Eventdate,
cit.CitationID,
cit.SourceID,
cit.SourceName,
ev.proof,
ev.placeID,
ev.SiteID, 
pl.Placename, 
pl.placedetailname, 
ev.details
/* join in the citation CTE */
from ev left outer join cit on ev.eventID = cit.OwnerID
/* join in person where owner type is person */
LEFT OUTER JOIN pers ON
         ev.OwnerID = pers.RIN1 and ev.OwnerType = 0
/* join in the family persons for owner type = family */
LEFT OUTER JOIN fam ON
         ev.OwnerID = fam.FamilyID and ev.OwnerType = 1
/* join in the place and detail */
left outer join pl
ON ev.placeid = pl.placeID and ev.siteID = pl.PlaceDetailID
WHERE    ev.EventType <> 35 /* ignore reference numbers */
/* and (ev.Proof = 0 or cit.CitationID is null) – not proven or no citation for fact (remove surrounding comment markers to include this restriction)*/
ORDER BY Surname, given, RIN1, eventtype
