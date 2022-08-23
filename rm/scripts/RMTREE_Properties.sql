-- RMTREE_Properties.sql
/* 2022-05-02 Tom Holden ve3meo
Evolved from RMGC_Properties.sql for prior versions

-- Lists properties of RM8 database except for dates plus 
--   extra detail identifying possible problems
*/
-- Create a new empty RootsMagic database using the current version as a Control group 
--   and edit the line below with its correct name and path between the single quotes.
-- Do not edit 'CTL'
-- Execute the next line: 
ATTACH 'C:\Users\Tom\Documents\FamilyTree\RM8\sql-dvlp\Empty.rmtree' AS 'CTL';
 
DROP TABLE IF EXISTS VariableTable;

CREATE TEMP TABLE IF NOT EXISTS VariableTable
(
Variable TEXT,
Value INTEGER,
Remark TEXT
);

INSERT INTO VariableTable
SELECT 'Version',
 (SELECT SUBSTR(SUBSTR(TRIM(DataRec),INSTR(DataRec,'<Version>')+9),1,4) 
  FROM ConfigTable WHERE RecType=1)
  ,'vs Control version ' 
  || (SELECT SUBSTR(SUBSTR(TRIM(DataRec),INSTR(DataRec,'<Version>')+9),1,4) 
  FROM CTL.ConfigTable WHERE RecType=1)
;

INSERT INTO VariableTable
SELECT '- pre/post RM8 release',null,
CASE 
  WHEN (SELECT Value FROM VariableTable WHERE Variable LIKE 'Version') < 8000 
    THEN 'WARNING! Database from a pre-release version of RM8'
  ELSE 'Database from a post-release version of RM8'
END
;

INSERT INTO VariableTable
SELECT 'People', COUNT(1), 'all records in PersonTable'
FROM PersonTable;
 
INSERT INTO VariableTable
SELECT '- Nameless People', COUNT(1), 'no record in NameTable for that RIN'
FROM PersonTable P 
LEFT JOIN nametable N
ON P.PersonID = N.OwnerID  AND n.ISPRIMARY
WHERE N.nameid ISNULL
;

DROP TABLE IF EXISTS namesort;
CREATE temp TABLE IF NOT EXISTS namesort AS
SELECT ownerid, surname collate nocase || given collate nocase AS name FROM nametable ORDER BY surname COLLATE NOCASE, given COLLATE NOCASE;

CREATE INDEX IF NOT EXISTS idxNameSortName ON Namesort (NAME);
CREATE INDEX IF NOT EXISTS idxNameSortOwnerID ON Namesort (OwnerID);

INSERT INTO VariableTable
SELECT '- Unresolved Duplicate Name Pairs',COUNT(1), 'pairs of Given and Surnames, not flagged as "Not a Problem"' 
FROM
( SELECT n.ownerid AS ID1, n2.ownerid AS ID2 from namesort n INNER JOIN namesort n2 USING (name) where ID1<ID2
  EXCEPT SELECT ID1,ID2 FROM EXCLUSIONTABLE WHERE exclusiontype=1);

INSERT INTO VariableTable
SELECT '- Resolved* Duplicate Name Pairs',COUNT(1), 'flagged as "Not a Problem" - flags lost on transfer' 
FROM EXCLUSIONTABLE WHERE exclusiontype=1;
 
INSERT INTO VariableTable
SELECT '- Unresolved Duplicates with Media Links',COUNT(1), "secondary persons' links lost on merge" 
FROM
( SELECT n.ownerid AS ID1, n2.ownerid as ID2 FROM namesort n INNER JOIN namesort n2 USING (name) 
  INNER JOIN medialinktable ml ON n2.ownerid=ml.ownerid  
  where ID1<ID2 AND ml.ownertype=0
  EXCEPT SELECT ID1,ID2 FROM EXCLUSIONTABLE WHERE exclusiontype=1
  )
   ;
 
INSERT INTO VariableTable
SELECT 'Alternate names', COUNT(1), 'all records in NameTable where IsPrimary=0'
FROM NameTable
WHERE IsPrimary = 0;
 
INSERT INTO VariableTable
SELECT '- Orphaned Alternate names*', COUNT(1), 'no Primary name record found'
FROM NameTable na
LEFT JOIN nametable n
ON na.ownerid=n.Ownerid
WHERE NOT +na.IsPrimary AND +N.IsPrimary AND n.nameid ISNULL;
 
INSERT INTO VariableTable
SELECT 'Families', COUNT(1), 'all records in FamilyTable'
FROM FamilyTable;
 
INSERT INTO VariableTable
SELECT 'Fact Types', COUNT(1), 'no. of records from FactTypeTable' FROM FactTypeTable
;

INSERT INTO VariableTable
SELECT '- Custom Fact Types', COUNT(1), 'no. of custom Fact Types' FROM main.FactTypeTable 
 WHERE FactTypeID > (SELECT max (FactTypeID) FROM CTL.FactTypeTable)
;

INSERT INTO VariableTable
SELECT '- Customised Built-in Fact Types', COUNT(1), 'no. of built-in Fact Types modified' FROM 
 (
  -- List of customised built-in Fact Types
  SELECT FactTypeID, Name COLLATE NOCASE, Abbrev, GedcomTag, usevalue, usedate, UsePlace, Sentence FROM main.FactTypeTable 
    WHERE FactTypeID <= (SELECT max (FactTypeID) FROM CTL.FactTypeTable)    
    EXCEPT SELECT FactTypeID, Name COLLATE NOCASE, Abbrev, GedcomTag, usevalue, usedate, UsePlace, Sentence FROM CTL.FactTypeTable
  )
; 

INSERT INTO VariableTable
SELECT '- Unused Fact Types', COUNT(1), 'no. of Fact Types not used' FROM 
 (
  -- List of unused Fact Types
  SELECT FactTypeID, Name COLLATE NOCASE, Sentence FROM main.FactTypeTable WHERE FactTypeID IN 
   (
    SELECT FactTypeID FROM main.FactTypeTable EXCEPT SELECT EventType FROM main.EventTable
    )    
  )
;

INSERT INTO VariableTable
SELECT '- Blank Fact Type Names', COUNT(1), 'FactTypes must be named' FROM 
 (
  -- List
  SELECT FactTypeID, Name COLLATE NOCASE, Sentence FROM FactTypeTable WHERE Name COLLATE NOCASE LIKE ''
  )
;

INSERT INTO VariableTable
SELECT '- Blank FactType Sentences', COUNT(1), 'FactType needing definition' FROM 
 (
  -- List
  SELECT FactTypeID, Name COLLATE NOCASE, Sentence FROM FactTypeTable WHERE Sentence LIKE ''
  )
;

INSERT INTO VariableTable
SELECT 'Events', COUNT(1), 'all records of EventTable'
FROM EventTable;
 
INSERT INTO VariableTable
SELECT '- Orphaned Events', SUM(Ctr), 'events for which no person or family match in respective tables' 
FROM
(
SELECT '- Orphaned Personal Events', COUNT(1) AS Ctr
FROM EventTable E
LEFT JOIN persontable p
ON e.OWNERID=p.PersonID 
LEFT JOIN nametable n
ON p.PERSONID=N.OwnerID 
WHERE e.OWNERTYPE=0  AND n.ISPRIMARY AND n.nameid ISNULL
UNION ALL
SELECT '- Orphaned Family Events', COUNT(1)
FROM EventTable E
LEFT JOIN familytable fm
ON e.OWNERID=fm.FamilyID 
WHERE e.OWNERTYPE=1 AND fm.FamilyID ISNULL
)
;

INSERT INTO VariableTable
SELECT '- Event Witnesses', COUNT(1), 'All records in WitnessTable of persons sharing events' FROM Witnesstable
;

INSERT INTO VariableTable
SELECT '-- Nominal Witnesses', COUNT(1), 'not Persons from database, but named in WitnessTable as sharing an event' FROM Witnesstable WHERE PersonID = 0 
;

INSERT INTO VariableTable
SELECT '-- Headless Witnesses', COUNT(1), 'PersonID (RIN) in WitnessTable missing from PersonTable' FROM
 (
  -- List of RINs of Headless Witnesses
  SELECT PersonID FROM WitnessTable WHERE WitnessTable.PersonID > 0
   EXCEPT SELECT PersonID FROM PersonTable   
  )
;

INSERT INTO VariableTable
SELECT '-- Witnesses to Lost Events', COUNT(1), 'EventID in WitnessTable cannot be found in EventTable' FROM
 (
  -- List of Witnesses to Lost Events  
  SELECT [WitnessID],[EventID],[PersonID],[WitnessOrder],[Role],[Sentence],[Note],[Given] COLLATE NOCASE,[Surname] COLLATE NOCASE,[Prefix] COLLATE NOCASE,[Suffix] COLLATE NOCASE FROM WitnessTable WHERE EventID IN  
   (
    -- List of EventIDs of Lost Events with Witnesses
    SELECT EventID FROM WitnessTable 
     EXCEPT SELECT EventID FROM EventTable
    )    
  )
;

INSERT INTO VariableTable
SELECT '-- Witnesses with blank Role', count(1), 'no role has been assigned from RoleTable or the RoleTable role is empty' FROM 
 ( 
  -- List of Witnesses with Blank Role  
  SELECT [WitnessID],[EventID],[PersonID],[WitnessOrder],[Role],W.[Sentence],[Note],[Given] COLLATE NOCASE,[Surname] COLLATE NOCASE,[Prefix] COLLATE NOCASE,[Suffix] COLLATE NOCASE  FROM WitnessTable W, RoleTable WHERE Role LIKE RoleID AND RoleName COLLATE NOCASE LIKE ''
  ) 
;

INSERT INTO VariableTable
SELECT '-- Witnesses with Custom Sentence', count(1), 'a custom sentence has been assigned, unique to this witness' FROM 
 ( 
  -- List of Witnesses with Custom Sentence  
  SELECT [WitnessID],[EventID],[PersonID],[WitnessOrder],[Role],W.[Sentence],[Note],[Given] COLLATE NOCASE,[Surname] COLLATE NOCASE,[Prefix] COLLATE NOCASE,[Suffix] COLLATE NOCASE  FROM WitnessTable W, RoleTable WHERE Role LIKE RoleID AND W.Sentence NOT LIKE ''
  ) 
;

INSERT INTO VariableTable
SELECT '-- Witnesses with Note', count(1), 'a note has been entered for this witness to an event' FROM 
 ( 
  -- List of Witnesses with Note  
  SELECT [WitnessID],[EventID],[PersonID],[WitnessOrder],[Role],W.[Sentence],[Note],[Given] COLLATE NOCASE,[Surname] COLLATE NOCASE,[Prefix] COLLATE NOCASE,[Suffix] COLLATE NOCASE  FROM WitnessTable W, RoleTable WHERE Role LIKE RoleID AND Note NOT LIKE ''
  ) 
;
 
INSERT INTO VariableTable
SELECT '-- Roles', COUNT(1), 'no. of records from RoleTable' FROM roletable
;

INSERT INTO VariableTable
SELECT '--- Custom Roles', COUNT(1), 'no. of custom roles' FROM main.RoleTable 
 WHERE RoleID > (SELECT max (RoleID) FROM CTL.roletable)
;

INSERT INTO VariableTable
SELECT '--- Customised Built-in Roles', COUNT(1), 'no. of built-in roles modified' FROM 
 (
  -- List of customised built-in roles
  SELECT RoleID, RoleName COLLATE NOCASE, EventType, RoleType, Sentence FROM main.RoleTable 
    WHERE RoleID <= (SELECT max (RoleID) FROM CTL.roletable)    
    EXCEPT SELECT RoleID, RoleName COLLATE NOCASE, EventType, RoleType, Sentence FROM CTL.RoleTable
  )
; 

INSERT INTO VariableTable
SELECT '--- Unused Roles', COUNT(1), 'no. of roles not used' FROM 
 (
  -- List of unused roles
  SELECT RoleID, RoleName COLLATE NOCASE, EventType, RoleType, Sentence FROM main.RoleTable WHERE RoleID IN 
   (
    SELECT RoleID FROM main.RoleTable EXCEPT SELECT Role FROM main.WitnessTable
    )    
  )
;

INSERT INTO VariableTable
SELECT '--- Blank Role Names', COUNT(1), 'Roles needing definition' FROM 
 (
  -- List
  SELECT RoleID, RoleName COLLATE NOCASE, EventType, RoleType, Sentence FROM RoleTable WHERE rolename COLLATE NOCASE LIKE ''
  )
;


INSERT INTO VariableTable
SELECT '--- Blank Role Sentences', COUNT(1), 'Roles needing definition' FROM 
 (
  -- List
  SELECT RoleID, RoleName COLLATE NOCASE, EventType, RoleType, Sentence FROM RoleTable WHERE Sentence LIKE ''
  )
;

INSERT INTO VariableTable
SELECT 'Total Places', COUNT(1), 'all records in PlaceTable incl Places and Place Details (Sites)'
FROM PlaceTable
;
 
INSERT INTO VariableTable
SELECT '- System Places', COUNT(1), 'system supplied Places: LDS Temples'
FROM PlaceTable
WHERE PlaceType = 1
;
 
INSERT INTO VariableTable
SELECT '- User Places', COUNT(1), 'user defined Places excl Sites'
FROM PlaceTable
WHERE PlaceType = 0
;
 
INSERT INTO VariableTable
SELECT '-- Used, having Geo-coordinates', COUNT(1), 'non-empty Lat or Long'
FROM (SELECT P.PlaceID 
     FROM PlaceTable P, eventtable e
     WHERE P.PlaceType = 0 AND P.Latitude +P.Longitude <> 0 
     AND P.PlaceID=E.PlaceID
     GROUP BY P.PlaceID)
;

INSERT INTO VariableTable
SELECT '-- Unused User Places*', COUNT(1), 'not used by EventTable, will be dropped in a transfer'
 FROM PlaceTable,       
 (SELECT PlaceTable.PlaceID AS unusedPlaceID          
  FROM PlaceTable 
  WHERE placetable.PlaceType = 0         
  EXCEPT SELECT eventtable.PlaceID           
         FROM eventtable   
)      
  WHERE PlaceTable.PlaceID = unusedPlaceID;

INSERT INTO VariableTable
SELECT '-- User Place Details', COUNT(1), 'user defined Sites'
FROM PlaceTable
WHERE PlaceType = 2;

INSERT INTO VariableTable
SELECT '--- Used, having Place Detail Notes*', COUNT(1), 'Site Notes will be lost in a transfer'
FROM (SELECT PD.PlaceID 
     FROM PlaceTable PD, PlaceTable P, eventtable e
     WHERE PD.PlaceType = 2 AND PD.Note <> '' AND PD.MasterID=P.PlaceID 
     AND PD.MasterID=E.PlaceID AND PD.PlaceID=E.SiteID
     GROUP BY PD.PlaceID)
;

INSERT INTO VariableTable
SELECT '--- Used, having Geo-coordinates', COUNT(1), 'non-empty Lat or Long'
FROM (SELECT PD.PlaceID 
     FROM PlaceTable PD, PlaceTable P, eventtable e
     WHERE PD.PlaceType = 2 AND PD.Latitude +PD.Longitude <> 0 AND PD.MasterID=P.PlaceID 
     AND PD.MasterID=E.PlaceID AND PD.PlaceID=E.SiteID
     GROUP BY PD.PlaceID)
;

INSERT INTO VariableTable
SELECT '--- Unused Place Details*', COUNT(1), 'Sites will be lost in a transfer'
FROM PlaceTable PD 
LEFT JOIN PlaceTable P ON PD.MasterID=P.PlaceID
LEFT JOIN eventtable e ON (PD.MasterID=E.PlaceID AND PD.PlaceID=E.SiteID)
WHERE PD.PlaceType = 2 AND E.EVENTID ISNULL
;

INSERT INTO VariableTable
SELECT 'Source Templates', COUNT(1), '# of records from SourceTemplateTable' FROM SourceTemplateTable
;

INSERT INTO VariableTable
SELECT '- Custom Source Templates', COUNT(1), '# of custom Source Templates' FROM main.SourceTemplateTable 
 WHERE TemplateID > 9999
;

INSERT INTO VariableTable
SELECT '- Unupdated Built-in SourceTemplates', COUNT(1), '# not matching reference database' FROM 
 (
  -- List of customised built-in SourceTemplates
  SELECT TemplateID, Name COLLATE NOCASE, [Description],[Footnote],[ShortFootnote],[Bibliography],[FieldDefs] FROM main.SourceTemplateTable 
    WHERE TemplateID <= 9999    
    EXCEPT SELECT TemplateID, Name COLLATE NOCASE, [Description],[Footnote],[ShortFootnote],[Bibliography],[FieldDefs] FROM CTL.SourceTemplateTable
  )
; 

INSERT INTO VariableTable
SELECT '- Unused Custom SourceTemplates*', COUNT(1), 'lost on transfer' FROM 
 (
  -- List of unused Custom SourceTemplates
  SELECT TemplateID, Name COLLATE NOCASE FROM main.SourceTemplateTable WHERE TemplateID>9999 AND TemplateID IN 
   (
    SELECT TemplateID FROM main.SourceTemplateTable EXCEPT SELECT TemplateID FROM main.SourceTable
    )    
  )
;

INSERT INTO VariableTable
SELECT '- Incomplete Source Templates', COUNT(1), 'missing part of definition' FROM 
 (
  -- List
  SELECT TemplateID, Name COLLATE NOCASE, [Description],[Footnote],[ShortFootnote],[Bibliography],[FieldDefs] FROM main.SourceTemplateTable
  WHERE Name COLLATE NOCASE LIKE '' OR   
        [Description] LIKE '' OR   
        [Footnote] LIKE '' OR   
        [ShortFootnote] LIKE '' OR   
        [Bibliography] LIKE '' OR   
        [FieldDefs] LIKE '%<FIELDS/>%'
  )
;

INSERT INTO VariableTable
SELECT 'Total Sources', COUNT(1), 'all records from SourceTable'
FROM SourceTable;
 
INSERT INTO VariableTable
SELECT '- Unused Sources*', COUNT(1), 'SourceTable records unused by CitationTable'
FROM sourcetable s LEFT OUTER JOIN citationtable c
ON s.SOURCEID = c.SOURCEID 
WHERE c.SourceID ISNULL;
 
INSERT INTO VariableTable
SELECT 'Total Citations', COUNT(1), 'all records from CitationTable'
FROM CitationTable;

INSERT INTO VariableTable
SELECT 'Total Citation Links', COUNT(1), 'all records from CitationLinkTable'
FROM CitationLinkTable;

-- BEGIN '- Duplicate Citations'--------------------------
DROP TABLE IF EXISTS tmpCitations
;
CREATE TEMP TABLE tmpCitations (CITID INTEGER, SrcID INTEGER, RIN INTEGER, Dupes INTEGER, RinCitation TEXT);

INSERT INTO tmpCitations 
-- all Personal (General) citations
SELECT  c.CITATIONID, c.sourceid AS SrcID, n.ownerid AS RIN, COUNT(1)-1 AS Dupes, 
  QUOTE(n.OwnerID) || 'Personal' || QUOTE(s.NAME) || QUOTE(s.refnumber) || QUOTE(s.actualtext) || QUOTE(s.comments) || QUOTE(CAST(s.Fields AS TEXT)) || QUOTE(mm1.mediafile) 
  || QUOTE(c.refnumber) || QUOTE(c.actualtext) || QUOTE(c.comments) || QUOTE(CAST(c.Fields AS TEXT)) || QUOTE(mm2.mediafile) 
  AS RinCitation
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN persontable p ON cl.ownerid=p.personid 
  LEFT OUTER JOIN  nametable n ON p.personid=n.ownerid
  LEFT OUTER JOIN medialinktable ml1 ON s.SourceID=ml1.OwnerID AND ml1.OwnerType=3 
  LEFT OUTER JOIN multimediatable mm1 ON ml1.MediaID=mm1.MediaID    
  LEFT OUTER JOIN medialinktable ml2 ON c.CitationID=ml2.OwnerID  AND ml2.OwnerType=4 
  LEFT OUTER JOIN multimediatable mm2 ON ml2.MediaID=mm2.MediaID    
WHERE  cl.ownertype=0 AND +n.IsPrimary=1
GROUP BY RinCitation

UNION ALL
-- all Fact citations for Individual
SELECT  c.CITATIONID, c.sourceid AS SrcID, n.ownerid AS RIN, COUNT(1)-1 AS Dupes, 
  QUOTE(n.OwnerID) || QUOTE(f.NAME) || QUOTE(e.EventID) || QUOTE(s.NAME) || QUOTE(s.refnumber) || QUOTE(s.actualtext) || QUOTE(s.comments) || QUOTE(CAST(s.Fields AS TEXT)) || QUOTE(mm1.mediafile) 
  || QUOTE(c.refnumber) || QUOTE(c.actualtext) || QUOTE(c.comments) || QUOTE(CAST(c.Fields AS TEXT)) || QUOTE(mm2.mediafile) 
  AS RinCitation
FROM  citationtable c
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid
  LEFT OUTER JOIN eventtable e ON CL.ownerid=e.eventid
  LEFT OUTER JOIN persontable p ON e.ownerid=p.personid
  LEFT OUTER JOIN nametable n ON p.personid=n.ownerid
  LEFT OUTER JOIN facttypetable f ON e.eventtype=f.facttypeid  
  LEFT OUTER JOIN medialinktable ml1 ON s.SourceID=ml1.OwnerID AND ml1.OwnerType=3 
  LEFT OUTER JOIN multimediatable mm1 ON ml1.MediaID=mm1.MediaID    
  LEFT OUTER JOIN medialinktable ml2 ON c.CitationID=ml2.OwnerID  AND ml2.OwnerType=4 
  LEFT OUTER JOIN multimediatable mm2 ON ml2.MediaID=mm2.MediaID    
WHERE CL.ownertype=2 AND e.ownertype=0 AND f.ownertype=0 AND +n.IsPrimary=1 
GROUP BY RinCitation

UNION ALL
-- all Couple citations for Father|Husband|Partner 1
SELECT  c.CITATIONID, c.sourceid AS SrcID, n.ownerid AS RIN, COUNT(1)-1 AS Dupes, 
  QUOTE(n.OwnerID) || QUOTE(f.NAME) || QUOTE(e.EventID) || s.NAME || s.refnumber || QUOTE(s.actualtext) || QUOTE(s.comments) || (s.Fields) || QUOTE(mm1.mediafile) || 
  c.refnumber || QUOTE(c.actualtext) || QUOTE(c.comments) || (c.Fields) || QUOTE(mm2.mediafile) AS RinCitation
FROM  citationtable c
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN familytable fm ON CL.ownerid=fm.FamilyID
  LEFT OUTER JOIN persontable p ON fm.fatherid=p.personid
  LEFT OUTER JOIN nametable n ON p.personid=n.ownerid
  LEFT OUTER JOIN eventtable e ON e.ownerid=fm.familyid
  LEFT OUTER JOIN facttypetable f ON e.eventtype=f.facttypeid
  LEFT OUTER JOIN medialinktable ml1 ON s.SourceID=ml1.OwnerID AND ml1.OwnerType=3 
  LEFT OUTER JOIN multimediatable mm1 ON ml1.MediaID=mm1.MediaID    
  LEFT OUTER JOIN medialinktable ml2 ON c.CitationID=ml2.OwnerID  AND ml2.OwnerType=4 
  LEFT OUTER JOIN multimediatable mm2 ON ml2.MediaID=mm2.MediaID    
WHERE CL.ownertype=1 AND e.ownertype=1 AND f.ownertype=1 AND +n.IsPrimary=1
GROUP BY RinCitation

UNION ALL
-- Citations for Alternate Names 
SELECT  c.CITATIONID, c.sourceid AS SrcID, n.ownerid AS RIN, COUNT(1)-1 AS Dupes, 
  n.OwnerID || 'Alternate Name' || s.NAME || s.refnumber || QUOTE(s.actualtext) || QUOTE(s.comments) || (s.Fields) || QUOTE(mm1.mediafile) || 
  c.refnumber || QUOTE(c.actualtext) || QUOTE(c.comments) || (c.Fields) || QUOTE(mm2.mediafile) AS RinCitation
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN  nametable n ON n.nameid=CL.ownerid
  LEFT OUTER JOIN medialinktable ml1 ON s.SourceID=ml1.OwnerID AND ml1.OwnerType=3 
  LEFT OUTER JOIN multimediatable mm1 ON ml1.MediaID=mm1.MediaID    
  LEFT OUTER JOIN medialinktable ml2 ON c.CitationID=ml2.OwnerID  AND ml2.OwnerType=4 
  LEFT OUTER JOIN multimediatable mm2 ON ml2.MediaID=mm2.MediaID    
WHERE  CL.ownertype=7 AND +n.IsPrimary=0
GROUP BY RinCitation
--ORDER BY rincitation 
;

-- Count duplicates

INSERT INTO VariableTable
SELECT '- Duplicate Citations', SUM(Dupes), 'identical in most respects, cluttering reports' 
  FROM tmpcitations
;
-- END '- Duplicate Citations' ----------------------------- 


INSERT INTO VariableTable
SELECT '- Sourceless Citations*', COUNT(1), 'no SourceTable record for this CitationTable record'
FROM CitationTable c LEFT OUTER JOIN sourcetable s
ON s.SOURCEID = c.SOURCEID
WHERE s.SourceID ISNULL;

INSERT INTO VariableTable
SELECT '- Headless Citations*', SUM(ctr), 'CitationTable records for which no Person, Event, Family, AltName found; cleaned on transfer' 
FROM
(
SELECT '- Headless Personal Citations', COUNT(1) AS ctr
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN persontable p ON CL.ownerid=p.personid 
  LEFT OUTER JOIN  nametable n ON p.personid=n.ownerid
WHERE  CL.ownertype=0 AND n.ownerid ISNULL
UNION ALL
SELECT '- Headless Fact Citations', COUNT(1)
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid
  LEFT OUTER JOIN eventtable e ON CL.ownerid=e.eventid
  LEFT OUTER JOIN persontable p ON e.ownerid=p.personid
  LEFT OUTER JOIN nametable n ON p.personid=n.ownerid
  LEFT OUTER JOIN facttypetable f ON e.eventtype=f.facttypeid
WHERE CL.ownertype=2 AND n.ownerid ISNULL
UNION ALL
SELECT '- Headless Spouse Citations', COUNT(1)
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN familytable fm ON CL.ownerid=fm.FamilyID
  LEFT OUTER JOIN persontable p ON fm.fatherid=p.personid
  LEFT OUTER JOIN nametable n ON p.personid=n.ownerid
WHERE CL.ownertype=1  AND n.ownerid ISNULL
UNION ALL
SELECT '- Headless Family Citations', COUNT(1)
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN familytable fm ON CL.ownerid=fm.FamilyID
  LEFT OUTER JOIN persontable p ON fm.fatherid=p.personid
  LEFT OUTER JOIN nametable n ON p.personid=n.ownerid
  LEFT OUTER JOIN eventtable e ON e.ownerid=fm.familyid
  LEFT OUTER JOIN facttypetable f ON e.eventtype=f.facttypeid
WHERE CL.ownertype=1 AND e.ownertype=1 AND f.ownertype=1 AND n.ownerid ISNULL
UNION ALL
SELECT '- Headless Alt Name Citations', COUNT(1)
FROM  citationtable c 
  LEFT OUTER JOIN CitationLinkTable CL USING(CitationID)
  LEFT OUTER JOIN sourcetable s ON c.sourceid=s.sourceid 
  LEFT OUTER JOIN  nametable n ON n.nameid=CL.ownerid
WHERE  CL.ownertype=7 AND (n.nameid ISNULL OR +N.IsPrimary)
);

INSERT INTO VariableTable
SELECT 'Repositories', COUNT(1), 'all records from AddressTable of type Repository'
FROM AddressTable
WHERE AddressType = 1;
 
INSERT INTO VariableTable
SELECT 'Multimedia items', COUNT(1), 'all records from MultimediaTable'
FROM MultimediaTable;
 
INSERT INTO VariableTable
SELECT '- lacking thumbnail', COUNT(1), 'probably an imported reference to an image file that has yet to be found'
FROM MultimediaTable 
WHERE mediatype=1 AND thumbnail ISNULL;
-- if thumbnails stored for other types revise

INSERT INTO VariableTable
SELECT '- duplicate multimedia filenames', SUM(DUPES), 'probably having different paths'
 FROM
 (
  SELECT MediaFile COLLATE NOCASE, COUNT(*)-1 AS DUPES FROM MultimediaTable 
    GROUP BY MediaFile COLLATE NOCASE
  )
;

INSERT INTO VariableTable
SELECT '- with Date & Description*', COUNT(1), '(TBC) if a record has both, the Description is lost in a transfer'
FROM MultimediaTable m
WHERE m.Date <>'.' AND m.Description LIKE '%_' 
;

--MULTIMEDIALINKS 
INSERT INTO VariableTable
SELECT 'Multimedia links', COUNT(1), 'all records from MediaLinkTable'
FROM MediaLinkTable;
 
INSERT INTO VariableTable
SELECT '- duplicate multimedia links', SUM(DUPES), 'image appears multiple times for person, fact'
 FROM
 (
  SELECT MediaID, COUNT(*)-1 AS DUPES FROM MediaLinkTable
  GROUP BY MediaID, OwnerType, OwnerID, IsPrimary, Include1, Include2, Include3, Include4, SortOrder, RectLeft, RectTop, RectRight, RectBottom 
  )
;

INSERT INTO VariableTable
SELECT 'Addresses', COUNT(1), 'all records from AddressTable of type Address'
FROM AddressTable
WHERE AddressType = 0;
 
INSERT INTO VariableTable
SELECT '- blank names', COUNT(1), 'Name field of AddressTable record is blank' 
FROM AddressTable  
WHERE AddressType = 0 AND Name Collate NOCASE LIKE '';

-- TASKS 
INSERT INTO VariableTable
SELECT 'Tasks', COUNT(1), 'all records from TaskTable'
FROM TaskTable
;

INSERT INTO VariableTable
SELECT '- Research Log', COUNT(1), 'all records from TaskTable of Type 1'
FROM TaskTable
WHERE TaskType = 1;
 
INSERT INTO VariableTable
SELECT '- ToDo', COUNT(1), 'all records from TaskTable of Type 2'
FROM TaskTable
WHERE TaskType = 2;
 
INSERT INTO VariableTable
SELECT '- Correspondence', COUNT(1), 'all records from TaskTable of Type 3'
FROM TaskTable
WHERE TaskType = 3;

INSERT INTO VariableTable
SELECT 'Folders', COUNT(1), 'all records from TagTable of Type 1'
FROM TagTable
WHERE TagType = 1;

INSERT INTO VariableTable
SELECT 'Groups*', COUNT(1), 'all records from TagTable of Type 0'
FROM TagTable
WHERE TagType = 0;

INSERT INTO VARIABLETABLE
SELECT '* NOT TRANSFERABLE', NULL , 'via GEDCOM or Drag&Drop to another RM database';

-- reference database is unused beyond this point so detach it.
DETACH CTL
;

--      ****************************************************************************************
-- N.B. ***** To see results it may be necessary to re-run the following part of the query *****
--      ****************************************************************************************
SELECT Value, Variable, Remark FROM variabletable WHERE variable NOT LIKE 
CASE 
WHEN (:YforSummaryElseDetails) IN('y','Y') THEN '-%'
ELSE ''
END;
