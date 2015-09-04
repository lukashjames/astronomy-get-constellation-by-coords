DROP PROCEDURE IF EXISTS `HGTPRC`;
DELIMITER $$
CREATE PROCEDURE `HGTPRC`(
    IN `RA1` DOUBLE, 
    IN `DEC1` DOUBLE, 
    IN `EPOCH1` DOUBLE, 
    IN `EPOCH2` DOUBLE,
    IN `RA2` DOUBLE,
    IN `DEC2` DOUBLE,
    OUT `RA1_out` DOUBLE,
    OUT `DEC1_out` DOUBLE,
    OUT `EPOCH1_out` DOUBLE,
    OUT `EPOCH2_out` DOUBLE,
    OUT `RA2_out` DOUBLE,
    OUT `DEC2_out` DOUBLE
)
BEGIN
    -- HERGET PRECESSION, SEE P. 9 OF PUBL. CINCINNATI OBS. NO. 24
    -- INPUT=  RA1 AND DEC1 MEAN PLACE, IN RADIANS, FOR EPOCH1, IN YEARS A.D.
    -- OUTPUT= RA2 AND DEC2 MEAN PLACE, IN RADIANS, FOR EPOCH2, IN YEARS A.D.
    DECLARE `CDR`, `T`, `ST`, `A`, `B`, `C`, `EP1`, `EP2`, `CSR`, 
            `SINA`, `SINB`, `SINC`, `COSA`, `COSB`, `COSC` DOUBLE;
    DECLARE `R_i`, `R_j` TINYINT;
    DECLARE `R_val`, `X1_val` DOUBLE;
    DECLARE `X2_0`, `X2_1`, `X2_2` DOUBLE;
    DECLARE `done` TINYINT DEFAULT 0; -- for cursor

    CREATE TEMPORARY TABLE `R` (`i` TINYINT, `j` TINYINT, `val` DOUBLE);
    INSERT INTO `R` (`i`, `j`, `val`) 
        VALUES (0, 0, 0.0), (0, 1, 0.0), (0, 2, 0.0),
               (1, 0, 0.0), (1, 1, 0.0), (1, 2, 0.0),
               (2, 0, 0.0), (2, 1, 0.0), (2, 2, 0.0);
    DECLARE `from_R` CURSOR FOR SELECT `i`, `j`, `val` FROM `R` ORDER BY `i`, `j`;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET `done` = 1;
    
    SET `CDR` = 0.17453292519943e-01;
    SET `EP1` = 0.0;
    SET `EP2` = 0.0;
    --      COMPUTE INPUT DIRECTION COSINES
    SET `A` = COS(`DEC1`);
    
    -- instead array X1[3] 
    CREATE TEMPORARY TABLE `X1` (`i` TINYINT, `val` DOUBLE);
    INSERT INTO `X1` (`i`, `val`) VALUES (0, `A` * COS(`RA1`));
    INSERT INTO `X1` (`i`, `val`) VALUES (1, `A` * SIN(`RA1`));
    INSERT INTO `X1` (`i`, `val`) VALUES (2, SIN(`DEC1`));
    
    CREATE TEMPORARY TABLE `X2` (`i` TINYINT, `val` DOUBLE);
    INSERT INTO `X2` (`i`, `val`) VALUES (0, 0.0), (1, 0.0), (2, 0.0);
    
    
    --      SET UP ROTATION MATRIX (R)
    IF `EP1` = `EPOCH1` AND `EP2` = `EPOCH2` THEN
        SET `CDR` = `CDR` + 0.0;
    ELSE
        SET `CSR` = `CDR` / 3600.0;
        SET `T` = 0.001 * (`EPOCH2` - `EPOCH1`);
        SET `ST` = 0.001 * (`EPOCH1` - 1900.0);
        SET `A` = `CSR` * `T` * (23042.53 + `ST` * (139.75 + 0.06 * `ST`)
           + `T` * (30.23 - 0.27 * `ST` + 18.0 * `T`));
        SET `B` = `CSR` * `T` * `T` * (79.27 + 0.66 * `ST` + 0.32 * `T`) + `A`;
        SET `C` = `CSR` * `T` * (20046.85 - `ST` * (85.33 + 0.37 * `ST`) 
           + `T` * (-42.67 - 0.37 * `ST` - 41.8 * `T`));
        SET `SINA` = SIN(`A`);
        SET `SINB` = SIN(`B`);
        SET `SINC` = SIN(`C`);
        SET `COSA` = COS(`A`);
        SET `COSB` = COS(`B`);
        SET `COSC` = COS(`C`);
        -- fill array R[3][3]
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (0, 0, `COSA` * `COSB` * `COSC` - `SINA` * `SINB`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (0, 1, -`COSA` * `SINB` - `SINA` * `COSB` * `COSC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (0, 2, -`COSB` * `SINC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (1, 0, `SINA` * `COSB` + `COSA` * `SINB` * `COSC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (1, 1, `COSA` * `COSB` - `SINA` * `SINB` * `COSC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (1, 2, -`SINB` * `SINC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (2, 0, `COSA` * `SINC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (2, 1, -`SINA` * `SINC`);
        INSERT INTO `R` (`i`, `j`, `val`) VALUES (2, 2, `COSC`);
    END IF;
    -- PERFORM THE ROTATION TO GET THE DIRECTION COSINES AT EPOCH2
--    DECLARE `done` TINYINT DEFAULT 0;
--    DECLARE `from_R` CURSOR FOR SELECT `i`, `j`, `val` FROM `R` ORDER BY `i`, `j`;
--    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET `done` = 1;
--    OPEN `from_r`;
--    WHILE `done` = 0 DO
--        FETCH `from_r` INTO `R_i`, `R_j`, `R_val`;
--        SELECT `val` INTO `X1_val` FROM `X1` WHERE `i` = `R_j`;
--        UPDATE `X2` SET `val` = `val` + `R_val` * `X1_val` WHERE `i` = `R_i`;
--    END WHILE;
--    CLOSE `from_R`;
--    
--    SELECT `val` INTO `X2_0` FROM `X2` WHERE `i` = 0;
--    SELECT `val` INTO `X2_1` FROM `X2` WHERE `i` = 1;
--    SELECT `val` INTO `X2_2` FROM `X2` WHERE `i` = 2;
--    SET `RA2` = ATAN2(`X2_1`, `X2_0`);
--    IF (`RA2` < 0) THEN
--        SET `RA2` = 6.28318530717948 + `RA2`;
--    END IF;
--    SET `DEC2` = ASIN(`X2_2`);
--    DROP TABLE IF EXISTS `X1`;
--    DROP TABLE IF EXISTS `X2`;
--    DROP TABLE IF EXISTS `R`;
--    
--    SET `RA1_out` = `RA1`;
--    SET `DEC1_out` = `DEC1`;
--    SET `EPOCH1_out` = `EPOCH1`;
--    SET `EPOCH2_out` = `EPOCH2`;
--    SET `RA2_out` = `RA2`;
--    SET `DEC2_out` = `DEC2`;
END$$
DELIMITER ;
