Description
===========

This is SQL version of script constByCoords.pl. 

File data.dat placed into table *boundaries* (see .sql file).

File get_constell.sql contains stored procedure get_constellation_by_coords();

File HGTPRC.sql contains stored procedure HGTPRC(), using in get_constellation_by_coords().

Usage:
------

    MariaDB [astronomy]> CALL get_constellation_by_coords(6.75230861111, -16.7215361111, 0, @result);

**Query OK, 1 row affected (1,31 sec)**

    MariaDB [astronomy]> SELECT @result;

+---------+
| @result |
+---------+
| CMa     |
+---------+
1 row in set (0,00 sec)

