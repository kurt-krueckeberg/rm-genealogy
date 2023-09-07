-- Facts_shared-ChangeType-RM8.sql
/*
2014-10-21 Tom Holden ve3meo
2014-10-22 rev: Steps; added constraint on UPDATE; formatted.
2014-11-22 extended to support shared events
2021-12-30 adapted for RM8; fails on earlier versions

Requires SQLite Expert Personal with fake RMNOCASE extension loaded or an equivalent 
SQLite manager that also supports the entry of runtime variables.

It should not be necessary to execute the script in two steps as described below
but...

Highlight and execute Step 1 which requires that you enter accurately the
Abbrev values for the Fact Types you are changing from and to, from the Fact Type
List. Check the temp tables xEventOrigTable and xEventTargTable that they have 
but one record each and with a non-zero FactTypeID. If not, re-execute and 
correct your entries, else...

When satisfied, then highlight and execute Step 2. 

*/
---- STEP 1 ----
DROP TABLE
IF EXISTS xEventOrigTable;

CREATE TEMP TABLE xEventOrigTable AS
SELECT $EVENTTYPETOCHANGEFROM
	,FactTypeID
	,OwnerType
FROM FactTypeTable
WHERE Abbrev LIKE $EVENTTYPETOCHANGEFROM;

DROP TABLE
IF EXISTS xEventTargTable;

CREATE TEMP TABLE xEventTargTable AS
SELECT $EVENTTYPETOCHANGETO
	,FactTypeID
	,OwnerType
FROM FactTypeTable
WHERE Abbrev LIKE $EVENTTYPETOCHANGETO
	AND OwnerType = (
		SELECT OwnerType
		FROM xEventOrigTable
		) -- restrict to same fact level, i.e., Indiv or Fam
	;

---- STEP 2 ----

-- first revise the EventTable, then deal with the RoleTable and WitnessTable
UPDATE EventTable
SET [EventType] = (
		SELECT [FactTypeID]
		FROM xEventTargTable
		)
WHERE [EventType] = (
		SELECT [FactTypeID]
		FROM xEventOrigTable
		) -- only update those events whose EventTypeID matches the FactTypeID of $EventTypeToChangeFrom
	AND (
		SELECT [FactTypeID]
		FROM xEventTargTable
		) -- and only if there is a valid FactTypeID for $EventTypeToChangeTo
	;

-- role definitions from the original fact type need to be added to the target fact type
-- (at least those that are used)

DROP VIEW IF EXISTS RolesUsed
;

CREATE TEMP VIEW RolesUsed
AS
SELECT DISTINCT [Role] 
FROM WitnessTable
WHERE [Role] IN
 (SELECT [RoleID] 
  FROM RoleTable 
  WHERE [EventType] = 
   (SELECT [FactTypeID] 
    FROM xEventOrigTable
    )
   )
;

-- do any of the roles match target roles?
DROP VIEW IF EXISTS RoleMatches
;

CREATE TEMP VIEW RoleMatches
AS
SELECT Orig.[RoleID] AS OrigRole, Targ.[RoleID] AS TargRole
FROM RoleTable AS Orig, RoleTable Targ
WHERE [OrigRole] IN (SELECT [Role] FROM RolesUsed)
AND Targ.[EventType] = (SELECT [FactTypeID] FROM xEventTargTable)
AND Orig.[RoleName] LIKE Targ.[RoleName]
AND Orig.[Sentence] LIKE Targ.[Sentence]
;

-- revise WitnessTable where matching roles exist
UPDATE WitnessTable
SET Role = (SELECT [TargRole] FROM RoleMatches RM WHERE WitnessTable.[Role] = RM.[OrigRole])
WHERE WitnessTable.[Role] IN (SELECT [OrigRole] FROM RoleMatches)
;

-- add non-matching roles from the Original fact type to the Target fact type
-- and revise WitnessTable to point to them

DROP TABLE IF EXISTS RoleTranspose
;
CREATE TEMP TABLE RoleTranspose (IncRoleID INTEGER PRIMARY KEY, OrigRole INTEGER, NewRole INTEGER)
;

INSERT INTO RoleTranspose
SELECT Null, Role, Null FROM RolesUsed EXCEPT SELECT Null, OrigRole, Null FROM RoleMatches 
;

UPDATE RoleTranspose SET NewRole = (SELECT MAX(RowID) FROM RoleTable) + IncRoleID
;

-- create Roles for target fact type
INSERT INTO RoleTable
SELECT RT.NewRole AS RoleID
       , R.RoleName
       , (SELECT FactTypeID FROM xEventTargTable) AS EventType
       , R.RoleType
       , R.Sentence
       , NULL AS UTCModDate -- for RM8. Comment out for earlier.        
FROM RoleTranspose RT, RoleTable R
WHERE RT.OrigRole = R.RoleID
;

-- revise WitnessTable roles to the new roles for the target event type
UPDATE WitnessTable
SET Role = (SELECT NewRole FROM RoleTranspose RT WHERE WitnessTable.Role = RT.OrigRole)
WHERE Role IN (SELECT OrigRole FROM RoleTranspose)
;

	---- End of Script ----
-- temporary tables and views will be dropped when the database is closed by the SQLite manager.


