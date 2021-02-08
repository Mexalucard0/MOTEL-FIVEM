 CREATE TABLE IF NOT EXISTS `characters_storages` (
                `storageId` varchar(255) NOT NULL,
                `storageData` longtext NOT NULL,
                PRIMARY KEY (`storageId`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;