-- 3.3 crearea și întreținerea bazei de date
USE master
GO
DROP DATABASE IF EXISTS Music
CREATE DATABASE Music
ON PRIMARY
( NAME = Music, 
FILENAME = 'D:\ProiectBD\Music.mdf' ,
SIZE = 2MB,
MAXSIZE = 500MB),

( NAME = Music_Secundary,
FILENAME = 'D:\ProiectBD\Music_Secundary.ndf' ,
SIZE = 2MB, 
MAXSIZE = 500MB)

LOG ON
( NAME = Music_log,
FILENAME = 'D:\ProiectBD\Music_log.ldf' ,
SIZE = 2MB, 
MAXSIZE = 100MB)

-- Adauga un task nou, executat de SQL Server Agent service numit "MaintenancePlan".  
USE Music
EXEC msdb.dbo.sp_add_job  
   @job_name = 'MaintenancePlan',   
   @enabled = 1,   
   @description = 'Ruleaza în fiecare vineri' ; 
GO  

-- Spațiul liber pe pagină trebuie să fie 10 %
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'MaintenancePlan',
    @step_name = N'ShrinkStep1',
    @subsystem = N'TSQL',
    @command = N'DBCC SHRINKDATABASE ("Music", 10);  GO'

-- Operațiune trebuie să ruleze în fiecare vineri, la ora 00:00 
EXEC msdb.dbo.sp_add_schedule  
    @schedule_name = N'FridayShrink',  
    @enabled = 1,
    @freq_type = 8,   -- weekly
    @freq_recurrence_factor = 1,
    @freq_interval = 1,   -- once
    @active_start_time = 000000 ;   
GO  

EXEC msdb.dbo.sp_attach_schedule  
   @job_name = N'MaintenancePlan',  
   @schedule_name = N'FridayShrink' ;  
GO  

-- 3.4 Crearea și modificarea tabelelor 
DROP TABLE IF EXISTS Artist
CREATE TABLE Artist ( 
    ArtistId INT NOT NULL, 
    ArtistName VARCHAR(50) NOT NULL, 
	CONSTRAINT ArtistName UNIQUE (ArtistName),
    CONSTRAINT PK_ArtistId PRIMARY KEY (ArtistId)
)

DROP TABLE IF EXISTS Album
CREATE TABLE Album ( 
    AlbumId INT NOT NULL, 
    AlbumTitle VARCHAR(50) NOT NULL, 
	ArtistId INT NOT NULL, 
	CONSTRAINT AlbumTitle_ArtistId UNIQUE (AlbumTitle, ArtistId),
    CONSTRAINT PK_AlbumId PRIMARY KEY (AlbumId) 
) 

DROP TABLE IF EXISTS Track
CREATE TABLE Track ( 
    TrackId INT NOT NULL, 
    TrackTitle VARCHAR(50) NOT NULL,
	AlbumId INT NOT NULL, 
	GenreId INT NOT NULL, 
	CONSTRAINT TrackTitle UNIQUE (TrackTitle, AlbumId, GenreId),
    CONSTRAINT PK_TrackId PRIMARY KEY (TrackId) 
)

DROP TABLE IF EXISTS Genre
CREATE TABLE Genre ( 
    GenreId INT NOT NULL, 
    GenreName VARCHAR(50) NOT NULL, 
	CONSTRAINT GenreName UNIQUE (GenreName),
    CONSTRAINT PK_GenreId PRIMARY KEY (GenreId) 
)

-- 3.5 Crearea cheilor externe 
ALTER TABLE Album
ADD CONSTRAINT FK_Album_ArtistId FOREIGN KEY (ArtistId) REFERENCES Artist(ArtistId)

ALTER TABLE Track
ADD CONSTRAINT FK_Track_AlbumId FOREIGN KEY (AlbumId) REFERENCES Album(AlbumId),
	CONSTRAINT FK_Track_GenreId FOREIGN KEY (GenreId) REFERENCES Genre(GenreId)

-- 3.7 Crearea schemelor bazei de date 
IF EXISTS(
	SELECT sys.schemas.name FROM sys.schemas 
	WHERE sys.schemas.name='schema_Track')
DROP SCHEMA schema_Track
GO
CREATE SCHEMA schema_Track
GO
ALTER SCHEMA schema_Track TRANSFER dbo.Track

GO
IF EXISTS(
	SELECT sys.schemas.name FROM sys.schemas 
	WHERE sys.schemas.name='schema_Genre')
DROP SCHEMA schema_Genre
GO
CREATE SCHEMA schema_Genre
GO
ALTER SCHEMA schema_Genre TRANSFER dbo.Genre

-- 3.8 Crearea sinonimilor 
IF OBJECT_ID('GenreName','SN') IS NOT NULL 
DROP SYNONYM GenreName
CREATE SYNONYM GenreName FOR dbo.Genre.GenreName;

IF OBJECT_ID('TrackTitle','SN') IS NOT NULL 
DROP SYNONYM TrackTitle
CREATE SYNONYM TrackTitle FOR dbo.Track.TrackTitle;

-- 3.9 Înserarea valorilor în Baza de Date 
INSERT INTO Artist(ArtistId, ArtistName)
VALUES (1, 'Kendrick Lamar'),
	   (2, 'Fleetwood Mac'),
	   (3, 'Billie Eilish'),
	   (4, 'Bob Dylan'),
	   (5, 'Adele'),
	   (6, 'The Beatles');

INSERT INTO Album(AlbumId, AlbumTitle, ArtistId)
VALUES (1, 'To Pimp a Butterfly', 1),
	   (2, 'Rumours', 2),
	   (3, 'When We All Fall Asleep, Where Do We Go?', 3),
	   (4, 'Blood on the Tracks', 4),
	   (5, '21', 5),
	   (6, 'Sgt. Peppers Lonely Hearts Club Band', 6);

INSERT INTO schema_Genre.Genre(GenreId, GenreName)
VALUES (1, 'Hip-Hop/Rap'),
	   (2, 'Rock'),
	   (3, 'Pop/Electropop'),
	   (4, 'Folk/Rock'),
	   (5, 'Pop/Soul'),
	   (6, 'Jazz'),
	   (7, 'Classic');

INSERT INTO schema_Track.Track(TrackId, TrackTitle, AlbumId, GenreId)
VALUES (1, 'Alright', 1, 1),
	   (2, 'King Kunta', 1, 1),
	   (3, 'The Blacker the Berry', 1, 1),
	   (4, 'Go Your Own Way', 2, 2),
	   (5, 'Dreams', 2, 2),
	   (6, 'Dont Stop', 2, 2),
	   (7, 'bad guy', 3, 3),
	   (8, 'bury a friend', 3, 3),
	   (9, 'when the partys over', 3, 3),
	   (10, 'Tangled Up in Blue', 4, 4),
	   (11, 'Simple Twist of Fate', 4, 4),
	   (12, 'Shelter From the Storm', 4, 4),
	   (13, 'Someone Like You', 5, 5),
	   (14, 'Rolling in the Deep', 5, 5),
	   (15, 'Set Fire to the Rain', 5, 5),
	   (16, 'A Day in the Life', 6, 2),
	   (17, 'Lucy in the Sky with Diamonds', 6, 2),
	   (18, 'With a Little Help from My Friends', 6, 2);

SELECT * FROM Artist
SELECT * FROM Album
SELECT * FROM schema_Genre.Genre
SELECT * FROM schema_Track.Track

-- 3.10 Crearea și gestiunea interogărilor SQL
-- afișează numele artistului și numărul total de piese per album
SELECT a.ArtistName, Album.AlbumTitle, COUNT(t.TrackId) as TotalTracks
FROM Artist a
INNER JOIN Album ON a.ArtistId = Album.ArtistId
INNER JOIN schema_Track.Track t ON Album.AlbumId = t.AlbumId
GROUP BY a.ArtistName, Album.AlbumTitle

-- afișează numele artistului, numele albumului acestui artist si genul acestui album
SELECT ArtistName, AlbumTitle, GenreName
FROM Artist, Album, schema_Track.Track t, schema_Genre.Genre g
WHERE Artist.ArtistId = Album.ArtistId
AND Album.AlbumId = t.AlbumId
AND t.GenreId = g.GenreId
GROUP BY Artist.ArtistName, Album.AlbumTitle, g.GenreName

-- afiseaza numele artistului si titlul albumului care are cel putin o piesa in "Track" 
-- unde piesele sunt asociate cu genul "Rock"
SELECT ArtistName ,AlbumTitle
FROM Artist, Album
WHERE EXISTS (SELECT 1 FROM schema_Track.Track t
              WHERE Album.AlbumId = t.AlbumId 
              AND GenreId = (SELECT GenreId FROM schema_Genre.Genre WHERE GenreName = 'Rock'))
AND Artist.ArtistId = Album.ArtistId

-- adauga o coloana ReleaseYear de tip INT în tabelul "Album".
-- actualizează valorile pentru coloana "ReleaseYear" în funcție de valorile din coloana "AlbumTitle" existente în tabelul "Album"
ALTER TABLE Album
ADD ReleaseYear INT

UPDATE Album
SET ReleaseYear = 
    CASE 
        WHEN AlbumTitle = 'To Pimp a Butterfly' THEN 2015
        WHEN AlbumTitle = 'Rumours' THEN 1977
        WHEN AlbumTitle = 'When We All Fall Asleep, Where Do We Go?' THEN 2019
        WHEN AlbumTitle = 'Blood on the Tracks' THEN 1975
        WHEN AlbumTitle = '21' THEN 2011
        WHEN AlbumTitle = 'Sgt. Peppers Lonely Hearts Club Band' THEN 1967
    END

SELECT AlbumTitle, ArtistId, ReleaseYear FROM Album

-- adauga o coloana Sales de tip INT în tabelul "Track".
-- actualizează valorile pentru coloana "Sales" în funcție de valorile din coloana "TrackTitle" existente în tabelul "Track" 
ALTER TABLE schema_Track.Track 
ADD Sales INT

UPDATE schema_Track.Track 
SET Sales = 
    CASE 
        WHEN TrackTitle = 'Alright' THEN 500000
        WHEN TrackTitle = 'King Kunta' THEN 450000
        WHEN TrackTitle = 'The Blacker the Berry' THEN 400000
        WHEN TrackTitle = 'Go Your Own Way' THEN 350000
        WHEN TrackTitle = 'Dreams' THEN 300000
        WHEN TrackTitle = 'Dont Stop' THEN 250000
        WHEN TrackTitle = 'bad guy' THEN 200000
        WHEN TrackTitle = 'bury a friend' THEN 150000
        WHEN TrackTitle = 'when the partys over' THEN 100000
        WHEN TrackTitle = 'Tangled Up in Blue' THEN 50000
        WHEN TrackTitle = 'Simple Twist of Fate' THEN 40000
        WHEN TrackTitle = 'Shelter From the Storm' THEN 30000
        WHEN TrackTitle = 'Someone Like You' THEN 20000
        WHEN TrackTitle = 'Rolling in the Deep' THEN 10000
        WHEN TrackTitle = 'Set Fire to the Rain' THEN 5000
        WHEN TrackTitle = 'A Day in the Life' THEN 1000
        WHEN TrackTitle = 'Lucy in the Sky with Diamonds' THEN 500
        WHEN TrackTitle = 'With a Little Help from My Friends' THEN 100
    END

SELECT TrackTitle, Sales FROM schema_Track.Track 

-- 3.11 Crearea viziunilor 
-- crearea viziunii care afișează numele artistilor
IF OBJECT_ID('Artists', 'V') IS NOT NULL
DROP VIEW Artists
GO
CREATE VIEW Artists AS
SELECT ArtistName
FROM Artist
GO

SELECT * FROM Artists

-- modifica numele artistei Adele in Adele Laurie Blue Adkins
UPDATE Artists
SET ArtistName = 'Adele Laurie Blue Adkins'
WHERE ArtistName = 'Adele'
GO

SELECT * FROM Artists

-- crearea viziunii care afișează tracks
IF OBJECT_ID('Tracks', 'V') IS NOT NULL
DROP VIEW Tracks
GO
CREATE VIEW Tracks AS
SELECT TrackTitle
FROM schema_Track.Track
GO

SELECT * FROM Tracks

-- sterge piesa cu numele 'Rolling in the Deep'
DELETE FROM Tracks
WHERE TrackTitle = 'Rolling in the Deep'
GO

SELECT * FROM Tracks

-- 3.12 Crearea funcțiilor și procedurilor stocate
-- selectează piesele din tabelul "Track" ordonate după vânzări în ordine descrescătoare și returnează primele "nr" piese
DROP FUNCTION IF EXISTS dbo.getTopTracks
GO
CREATE FUNCTION getTopTracks (@num INT)
RETURNS TABLE
AS
RETURN (SELECT TrackId, TrackTitle, Sales
        FROM schema_Track.Track
        ORDER BY Sales DESC
        OFFSET 0 ROWS FETCH NEXT @num ROWS ONLY);
GO

SELECT * FROM getTopTracks(5)

-- returneaza numele artistului și suma vânzărilor pentru artistul cu un anumit ID 
DROP FUNCTION IF EXISTS dbo.getSalesByArtist
GO
CREATE FUNCTION getSalesByArtist (@artistId INT)
RETURNS TABLE
AS
RETURN (
    SELECT ar.ArtistName, SUM(Sales) as TotalSales
    FROM schema_Track.Track t
    JOIN Album a ON t.AlbumId = a.AlbumId
    JOIN Artist ar ON a.ArtistId = ar.ArtistId
    WHERE ar.ArtistId = @artistId
    GROUP BY ar.ArtistName
)
GO

SELECT * FROM getSalesByArtist(2)

-- procedura adauga un artist nou
DROP PROCEDURE IF EXISTS addArtist
GO
CREATE PROCEDURE addArtist
    @artistId INT,
    @artistName VARCHAR(50)
AS
BEGIN
    INSERT INTO Artist (ArtistId, ArtistName)
    VALUES (@artistId, @artistName)
END
GO

EXECUTE addArtist 7, 'Camila Cabello'
SELECT ArtistName FROM Artist

-- procedura adauga un album nou
DROP PROCEDURE IF EXISTS addAlbum
GO
CREATE PROCEDURE addAlbum
    @albumId INT,
    @albumTitle VARCHAR(50),
	@artistId INT
AS
BEGIN
    INSERT INTO Album(AlbumId, AlbumTitle, ArtistId)
    VALUES (@albumId, @albumTitle, @artistId)
END
GO

EXECUTE addAlbum 7, 'Happier Than Ever', 5
SELECT AlbumTitle FROM Album

-- 3.13 Crearea declanșatoarelor

-- declanşator DML, care ar urmări satisfacerea constrîngerii: 
-- AlbumTitle trebuie să fie UNIQUE și nu poate fi NULL 
-- pentru fiecare tuplu înserat, modificat sau şters

IF EXISTS (SELECT * FROM sys.triggers 
			WHERE name = 'TRIGGER_AlbumTitle_Unique'
)
BEGIN
	DROP TRIGGER TRIGGER_AlbumTitle_Unique
END
GO
CREATE TRIGGER TRIGGER_AlbumTitle_Unique
ON Album
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM Album WHERE AlbumTitle IS NULL))
	BEGIN
		RAISERROR ('AlbumTitle cannot be NULL', 16, 1);
		ROLLBACK
	END

	IF (EXISTS (
		SELECT 1 FROM Album 
		WHERE AlbumTitle IN (
			SELECT AlbumTitle FROM Album 
			GROUP BY AlbumTitle HAVING COUNT(*) > 1)))
	BEGIN
		RAISERROR ('AlbumTitle must be UNIQUE', 16, 1);
		ROLLBACK
	END
END

-- declanşator DML, care ar urmări satisfacerea constrîngerii: 
-- AlbumTitle trebuie să fie UNIQUE și nu poate fi NULL 
-- pentru fiecare tuplu înserat, modificat sau şters

IF EXISTS (SELECT * FROM sys.triggers 
			WHERE name = 'TRIGGER_ArtistName_Unique'
)
BEGIN
	DROP TRIGGER TRIGGER_ArtistName_Unique
END
GO
CREATE TRIGGER TRIGGER_ArtistName_Unique
ON Artist
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	IF (EXISTS (SELECT 1 FROM Artist WHERE ArtistName IS NULL))
	BEGIN
		RAISERROR ('ArtistName cannot be NULL', 16, 1);
		ROLLBACK
	END

	IF (EXISTS (
		SELECT 1 FROM Artist 
		WHERE ArtistName IN (
			SELECT ArtistName FROM Artist 
			GROUP BY ArtistName HAVING COUNT(*) > 1)))
	BEGIN
		RAISERROR ('ArtistName must be UNIQUE', 16, 1);
		ROLLBACK
	END
END