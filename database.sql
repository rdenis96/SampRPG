-- phpMyAdmin SQL Dump
-- version 4.8.5
-- https://www.phpmyadmin.net/
--
-- Gazdă: localhost
-- Timp de generare: iun. 26, 2019 la 06:32 AM
-- Versiune server: 8.0.13-4
-- Versiune PHP: 7.2.19-0ubuntu0.18.04.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Bază de date: `iyXLc8IQyh`
--

-- --------------------------------------------------------

--
-- Structură tabel pentru tabel `factionMembers`
--

CREATE TABLE `factionMembers` (
  `MemberID` int(11) NOT NULL,
  `FactionID` int(11) NOT NULL,
  `Rank` tinyint(4) NOT NULL DEFAULT '1',
  `JoinDate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Warns` tinyint(4) NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Eliminarea datelor din tabel `factionMembers`
--

INSERT INTO `factionMembers` (`MemberID`, `FactionID`, `Rank`, `Warns`) VALUES
(3, 2, 1, 0);

-- --------------------------------------------------------

--
-- Structură tabel pentru tabel `factions`
--

CREATE TABLE `factions` (
  `ID` int(11) NOT NULL,
  `Name` varchar(100) NOT NULL,
  `Level` int(11) NOT NULL,
  `LeaderID` int(11) NOT NULL DEFAULT '-1',
  `Motd` varchar(255) DEFAULT NULL,
  `Motm` varchar(255) DEFAULT NULL,
  `SpawnX` float NOT NULL DEFAULT '0',
  `SpawnY` float NOT NULL DEFAULT '0',
  `SpawnZ` float NOT NULL DEFAULT '0',
  `Interior` int(11) NOT NULL DEFAULT '0',
  `Color` varchar(10) NOT NULL,
  `PrimarySkinID` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Eliminarea datelor din tabel `factions`
--

INSERT INTO `factions` (`ID`, `Name`, `Level`, `LeaderID`, `Motd`, `Motm`, `SpawnX`, `SpawnY`, `SpawnZ`, `Interior`, `Color`, `PrimarySkinID`) VALUES
(1, 'Police Department', 8, -1, 'Place your own Police Department MOTD', 'Place your own Police Department MOTM', 0, 0, 0, 0, '0000FF', 280),
(2, 'Federal Bureau of Investigation', 8, 3, 'Federal Bureau of Investigation MOTD', 'Federal Bureau of Investigation MOTM', 312.081, -1512.48, 24.9219, 0, '4C4CFF', 286),
(3, 'National Guard', 8, -1, 'Place your own National Guard MOTD', 'Place your own National Guard MOTM', 223.066, 1872.61, 13.7344, 0, '16164C', 287),
(4, 'Medics', 5, -1, 'Place your own Medics MOTD', 'Place your own Medics MOTM', 0, 0, 0, 0, 'EC7C30', 274),
(0, 'None', 0, -1, 'Place your own Civil MOTD', 'Place your own Civil MOTM', 0, 0, 0, 0, 'FFFFFF', 1);

-- --------------------------------------------------------

--
-- Structură tabel pentru tabel `houses`
--

CREATE TABLE `houses` (
  `ID` int(11) NOT NULL,
  `Owner` varchar(50) NOT NULL DEFAULT 'None',
  `Class` varchar(10) NOT NULL DEFAULT '0',
  `Price` int(11) NOT NULL DEFAULT '0',
  `Interior` tinyint(3) NOT NULL DEFAULT '0',
  `World` tinyint(3) NOT NULL DEFAULT '0',
  `EntranceX` float NOT NULL DEFAULT '0',
  `EntranceY` float NOT NULL DEFAULT '0',
  `EntranceZ` float NOT NULL DEFAULT '0',
  `ExitX` float NOT NULL DEFAULT '0',
  `ExitY` float NOT NULL DEFAULT '0',
  `ExitZ` float NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Structură tabel pentru tabel `players`
--

CREATE TABLE `players` (
  `ID` int(11) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `Password` char(64) NOT NULL,
  `Salt` char(16) NOT NULL,
  `LoggedIn` tinyint(1) NOT NULL DEFAULT '0',
  `Admin` smallint(4) NOT NULL DEFAULT '0',
  `Skin` smallint(4) NOT NULL,
  `Health` float NOT NULL DEFAULT '100',
  `Armor` float NOT NULL DEFAULT '0',
  `Money` int(11) NOT NULL DEFAULT '500',
  `BankMoney` int(11) NOT NULL DEFAULT '0',
  `X` float NOT NULL DEFAULT '0',
  `Y` float NOT NULL DEFAULT '0',
  `Z` float NOT NULL DEFAULT '0',
  `Angle` float NOT NULL DEFAULT '0',
  `Interior` tinyint(3) NOT NULL DEFAULT '0',
  `FactionID` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Eliminarea datelor din tabel `players`
--

INSERT INTO `players` (`ID`, `Name`, `Password`, `Salt`, `LoggedIn`, `Admin`, `Skin`, `Health`, `Armor`, `Money`, `BankMoney`, `X`, `Y`, `Z`, `Angle`, `Interior`, `FactionID`) VALUES
(3, 'Denis', '4704C2C686C7D47B350A8DC2A0A02809909594C87CC21301B42FC90D9CF4D506', 'D(cmV]#i06}6vD;(', 0, 7, 286, 100, 0, 0, 0, 312.081, -1512.48, 24.9219, 341.827, 0, 2);

-- --------------------------------------------------------

--
-- Structură tabel pentru tabel `vehicles`
--

CREATE TABLE `vehicles` (
  `ID` int(11) NOT NULL,
  `Owner` varchar(50) NOT NULL DEFAULT 'None',
  `Model` smallint(4) NOT NULL DEFAULT '0',
  `Color_1` tinyint(3) NOT NULL DEFAULT '0',
  `Color_2` tinyint(3) NOT NULL DEFAULT '0',
  `X` float NOT NULL DEFAULT '0',
  `Y` float NOT NULL DEFAULT '0',
  `Z` float NOT NULL DEFAULT '0',
  `Angle` float NOT NULL DEFAULT '0',
  `Active` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Indexuri pentru tabele eliminate
--

--
-- Indexuri pentru tabele `factionMembers`
--
ALTER TABLE `factionMembers`
  ADD PRIMARY KEY (`MemberID`),
  ADD KEY `FactionID` (`FactionID`);

--
-- Indexuri pentru tabele `factions`
--
ALTER TABLE `factions`
  ADD PRIMARY KEY (`ID`);

--
-- Indexuri pentru tabele `houses`
--
ALTER TABLE `houses`
  ADD PRIMARY KEY (`ID`);

--
-- Indexuri pentru tabele `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `Name` (`Name`);

--
-- Indexuri pentru tabele `vehicles`
--
ALTER TABLE `vehicles`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT pentru tabele eliminate
--

--
-- AUTO_INCREMENT pentru tabele `houses`
--
ALTER TABLE `houses`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT pentru tabele `players`
--
ALTER TABLE `players`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT pentru tabele `vehicles`
--
ALTER TABLE `vehicles`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
