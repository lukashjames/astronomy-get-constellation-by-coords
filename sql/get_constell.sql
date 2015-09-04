DROP PROCEDURE IF EXISTS `get_constellation_by_coords`;
DELIMITER $$
CREATE PROCEDURE `get_constellation_by_coords`(
    IN `ra_inp` DOUBLE, 
    IN `dec_inp` DOUBLE, 
    IN `epoch` DOUBLE,
    OUT `CON` CHAR(3)
)
BEGIN
    DECLARE `CONVH` DOUBLE DEFAULT 0.2617993878;
    DECLARE `CONVD` DOUBLE DEFAULT 0.1745329251994e-01;
    DECLARE `PI4` DOUBLE DEFAULT 6.28318530717948;
    DECLARE `E75` DOUBLE DEFAULT 1875.0;
    DECLARE `ARAD`, `DRAD`, `A`, `D`, `E`, `RAH`, `RA`, `DEC`, `RAL`, `RAU`, `DECL`, `DECD` DOUBLE;

    IF `ra_inp` < 0.0 OR `ra_inp` >= 24.0 THEN
        SIGNAL SQLSTATE '42000' SET MESSAGE_TEXT = 'RA must be in range [0.0; 24)';
    END IF;
    IF `dec_inp` < -90.0 OR `dec_inp` > 90.0 THEN
        SIGNAL SQLSTATE '42000' SET MESSAGE_TEXT = 'DEC must be in range [-90; +90]';
    END IF;
    
    IF epoch = 0 OR epoch IS NULL THEN
        SET epoch = 2000;
    END IF;
    
    SET `RAH` = `ra_inp`;
    SET `DECD` = `dec_inp`;
    SET `E` = `epoch`;

    -- PRECESS POSITION TO 1875.0 EQUINOX #
    SET `ARAD` = `CONVH` * `RAH`;
    SET `DRAD` = `CONVD` * `DECD`;
        CALL `HGTPRC`(`ARAD`, `DRAD`, `E`, `E75`, `A`, `D`);
    IF `A` <  0.0 THEN
        SET `A` = `A` + `PI4`;
    END IF;
    IF `A` >= `PI4` THEN
        SET `A` = `A` - `PI4`;
    END IF;
    SET `RA` = `A` / `CONVH`;
    SET `DEC` = `D` / `CONVD`;
    
    /* FIND CONSTELLATION SUCH THAT THE DECLINATION ENTERED IS HIGHER THAN
       THE LOWER BOUNDARY OF THE CONSTELLATION WHEN THE UPPER AND LOWER
       RIGHT ASCENSIONS FOR THE CONSTELLATION BOUND THE ENTERED RIGHT
       ASCENSION
    */
    
    SELECT `constell` INTO `CON` FROM `boundaries` 
        WHERE (`RA` >= `ra_low` AND `RA` < `ra_up`) AND `de_low` <= `DEC`
        ORDER BY de_low DESC LIMIT 1;
    -- -- SELECT `CON` FROM DUAL;

--    RETURN `CON`;
END$$
DELIMITER ;
