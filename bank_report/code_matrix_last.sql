---tables--
CREATE TABLE Filiallar(filial_id NUMBER PRIMARY KEY,
                       Branch_DESCRIPTION VARCHAR2(100)
                       );
                       

                        
CREATE TABLE Valyutalar(val_id CHAR(3),
                        val_code NUMBER PRIMARY KEY
                        );
                        
CREATE TABLE Mezenneler(Mezenne_Tarix DATE,
                        Val_id REFERENCES Valyutalar(Val_Code),
                        Mezenne NUMBER
                        );
                        
CREATE TABLE Customer_4 (CUSTOMER_NO NUMBER,
                      CUSTOMER_TYPE CHAR(1),
                      CUSTOMER_FULL_NAME VARCHAR2(100),
                      ADDRESS_LINE1 VARCHAR2(100),
                      ADDRESS_LINE3 VARCHAR2(100),
                      ADDRESS_LINE2 VARCHAR2(100),
                      ADDRESS_LINE4 VARCHAR2(100),
                      COUNTRY CHAR(5),
                      LANGUAGE CHAR(5),
                      BRANCH_İD NUMBER REFERENCES Filiallar(Filial_Id),
                      SHEXS_VES_NO VARCHAR2(100),
                      LIMIT_1 NUMBER,
                      LIMIT_CCY NUMBER REFERENCES valyutalar(val_code)
                      );
                    
CREATE UNIQUE INDEX index_1 ON Customer_4  (CUSTOMER_NO);
SELECT * FROM Filiallar FOR UPDATE;
SELECT * FROM Valyutalar FOR UPDATE;
SELECT * FROM Mezenneler FOR UPDATE;
SELECT * FROM customer_4 FOR UPDATE;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--package specification--
CREATE OR REPLACE PACKAGE customer_systems IS
  FUNCTION calculation_of_valyuta(p_val_id NUMBER, p_date DATE) RETURN NUMBER;

  PROCEDURE update_customer(customer_id NUMBER);

  PROCEDURE update_customer(customer_id NUMBER, customer_type VARCHAR2);
END customer_systems;

--package body--
CREATE OR REPLACE PACKAGE BODY customer_systems IS

FUNCTION calculation_of_valyuta(p_val_id NUMBER, p_date DATE) RETURN NUMBER IS
v_exchange_rate NUMBER;
BEGIN
SELECT m.mezenne INTO v_exchange_rate FROM mezenneler m WHERE m.val_id = p_val_id AND m.mezenne_tarix = p_date; RETURN v_exchange_rate;
EXCEPTION
WHEN no_data_found THEN dbms_output.put_line('No data found');
END;

PROCEDURE update_customer(customer_id NUMBER) IS
BEGIN
UPDATE customer_4 c SET c.address_line2 = SUBSTR(c.address_line2, 1, 5) || '-' WHERE c.customer_no = customer_id;
END;

PROCEDURE update_customer(customer_id NUMBER, customer_type VARCHAR2) IS
BEGIN
UPDATE customer_4 c SET c.address_line1 = SUBSTR(c.address_line1, 1, 5) || c.address_line2 WHERE c.customer_no = customer_id AND c.customer_type = customer_type;
END;
END customer_systems;
--------------------Forma 1----------------------------------------------------------------------------------------------------------------------------------------
SELECT t.customer_type, NVL(SUM(CASE WHEN f.filial_id IN (0, 1, 3) THEN(t.limit_1 * customer_systems.calculation_of_valyuta(t.limit_ccy, to_date('24.02.2019', 'dd/mm/yyyy')))
END), 0) AS
"Bakı şeheri üzre summa", NVL(SUM(CASE WHEN f.filial_id = 2 THEN(t.limit_1 * customer_systems.calculation_of_valyuta(t.limit_ccy, to_date('24.02.2019', 'dd/mm/yyyy')))
END), 0) AS
"Sumqayıt şeheri üzre summa", NVL(SUM(CASE WHEN f.filial_id = 4 THEN(t.limit_1 * customer_systems.calculation_of_valyuta(t.limit_ccy, to_date('24.02.2019', 'dd/mm/yyyy')))
END), 0) AS
"Mingecevir şeheri üzre summa" FROM customer_4 t JOIN filiallar f ON t.branch_id = f.filial_id GROUP BY t.customer_type; ---cost4 24byte

-----------------Forma 2 --------------------------------------------------------------------------------------------------------
SELECT c.customer_type, SUBSTR(to_char(SUM(CASE WHEN c.country = 'AZ' THEN(c.limit_1 * customer_systems.calculation_of_valyuta(c.limit_ccy, to_date('01.03.2019', 'dd/mm/yyyy')))
/
1000
END), '999G999D99'), 1, 7) AS
azerbaycan, SUM(CASE WHEN c.country = 'TYR' THEN(c.limit_1 * customer_systems.calculation_of_valyuta(c.limit_ccy, to_date('01.03.2019', 'dd/mm/yyyy')))
/
1000
END) AS
turkiye, SUBSTR(to_char(SUM(CASE WHEN c.country = 'RU' THEN(c.limit_1 * customer_systems.calculation_of_valyuta(c.limit_ccy, to_date('01.03.2019', 'dd/mm/yyyy')))
/
1000
END), '999G999D99'), 1, 12) AS
rusiya, SUM(CASE WHEN c.country = 'AZ' THEN 1
END) AS
azerbaycan_say, SUM(CASE WHEN c.country = 'TYR' THEN 1
END) AS
turkiye_say, SUM(CASE WHEN c.country = 'RU' THEN 1
END) AS
rusiya_say FROM(SELECT customer_type, TRIM(nvl(country, 'AZ')) AS
country, limit_1 AS
limit_1, limit_ccy FROM customer_4) c GROUP BY c.customer_type; -- cost 28 byte
-------------------------------

--function execute---
SELECT customer_systems.calculation_of_valyuta(840, to_date('24.02.2019', 'dd/mm/yyyy')) FROM dual;
---procedure 1 execute---
BEGIN
customer_systems.update_customer(5977072);
END;
----procedure 2 execute--
BEGIN
customer_systems.update_customer(6160898, 'H');
END;
