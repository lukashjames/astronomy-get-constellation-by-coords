DROP FUNCTION IF EXISTS `get_constellation_by_coords`;
DELIMITER $$
CREATE FUNCTION `get_constellation_by_coords`(`ra` NUMERIC, `dec` NUMERIC, `epoch` NUMERIC) RETURNS NUMERIC
BEGIN
    IF `ra` < 0.0 OR `ra` >= 24.0 THEN
        SIGNAL SQLSTATE '42000' SET MESSAGE_TEXT = 'RA must be in range [0.0; 24)';
    END IF;
    IF `dec` < -90.0 OR `dec` > 90.0 THEN
        SIGNAL SQLSTATE '42000' SET MESSAGE_TEXT = 'DEC must be in range [-90; +90]';
    END IF;
    
    IF epoch = 0 OR epoch IS NULL THEN
        SET epoch = 2000;
    END IF;
    RETURN epoch;
END$$
DELIMITER ;
