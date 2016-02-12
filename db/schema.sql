DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS rental;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS store;
DROP TABLE IF EXISTS address;
DROP TABLE IF EXISTS city;
DROP TABLE IF EXISTS country;
DROP TABLE IF EXISTS film_text;
DROP TABLE IF EXISTS film_category;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS film_actor;
DROP TABLE IF EXISTS film;
DROP TABLE IF EXISTS language;
DROP TABLE IF EXISTS actor;

CREATE TABLE actor (
  actor_id    SMALLINT     UNSIGNED NOT NULL AUTO_INCREMENT,
                           -- 16-bit unsigned int in the range of [0, 65535]
  first_name  VARCHAR(45)  NOT NULL,
  last_name   VARCHAR(45)  NOT NULL,
  last_update TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (actor_id),
  KEY idx_actor_last_name (last_name)   -- To build index (non-unique) on last_name
);


CREATE TABLE language (
  language_id  TINYINT    UNSIGNED NOT NULL AUTO_INCREMENT,
                          -- 8-bit unsigned int [0, 255]
  name         CHAR(20)   NOT NULL,
  last_update  TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (language_id)
);

CREATE TABLE film (
  film_id              SMALLINT     UNSIGNED NOT NULL AUTO_INCREMENT,
  title                VARCHAR(255) NOT NULL,
  description          TEXT         DEFAULT NULL,       -- Up to 64KB
  release_year         YEAR         DEFAULT NULL,       -- 'yyyy'
  language_id          TINYINT      UNSIGNED NOT NULL,  -- 8-bit unsigned int [0, 255]
  original_language_id TINYINT      UNSIGNED DEFAULT NULL,
  rental_duration      TINYINT      UNSIGNED NOT NULL DEFAULT 3,
  rental_rate          DECIMAL(4,2) NOT NULL DEFAULT 4.99,  
                                    -- DECIMAL is precise and ideal for currency [99.99]. UNSIGNED?
  length               SMALLINT     UNSIGNED DEFAULT NULL,  -- 16-bit unsigned int [0, 65535]
  replacement_cost     DECIMAL(5,2) NOT NULL DEFAULT 19.99, -- [999.99], UNSIGNED??
  rating               ENUM('G','PG','PG-13','R','NC-17') DEFAULT 'G',
  special_features     SET('Trailers','Commentaries','Deleted Scenes','Behind the Scenes') DEFAULT NULL,
                                    -- Can take zero or more values from a SET
                                    -- But only one value from ENUM
  last_update          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (film_id),
  KEY idx_title (title),
  KEY idx_fk_language_id (language_id),
  KEY idx_fk_original_language_id (original_language_id),
        -- To build index on title, language_id, original_language_id and film_id (primary key)
  CONSTRAINT fk_film_language FOREIGN KEY (language_id) REFERENCES language (language_id)
  ON DELETE RESTRICT ON UPDATE CASCADE,
        -- Cannot delete parent record if there is any matching child record
        -- Update the matching child records if parent record is updated
  CONSTRAINT fk_film_language_original FOREIGN KEY (original_language_id) REFERENCES language (language_id)
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE film_actor (
  actor_id     SMALLINT UNSIGNED NOT NULL,
  film_id      SMALLINT UNSIGNED NOT NULL,
  last_update  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (actor_id, film_id),
  KEY idx_fk_film_id (film_id),
  CONSTRAINT fk_film_actor_actor FOREIGN KEY (actor_id) REFERENCES actor (actor_id) 
  ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_film_actor_film FOREIGN KEY (film_id) REFERENCES film (film_id) 
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE category (
  category_id  TINYINT      UNSIGNED NOT NULL AUTO_INCREMENT,
  name         VARCHAR(25)  NOT NULL,
  last_update  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (category_id)
);


CREATE TABLE film_category (
  film_id      SMALLINT   UNSIGNED NOT NULL,
  category_id  TINYINT    UNSIGNED NOT NULL,
  last_update  TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (film_id, category_id),
  CONSTRAINT fk_film_category_film FOREIGN KEY (film_id) REFERENCES film (film_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_film_category_category FOREIGN KEY (category_id) REFERENCES category (category_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE film_text (
  film_id      SMALLINT      NOT NULL,
  title        VARCHAR(255)  NOT NULL,
  description  TEXT,
  PRIMARY KEY  (film_id),
  FULLTEXT KEY idx_title_description (title, description)
     -- To build index on FULLTEXT to facilitate text search
     -- FULLTEXT is supported in MyISAM engine, NOT in InnoDB engine
);

CREATE TABLE country (
  country_id   SMALLINT    UNSIGNED NOT NULL AUTO_INCREMENT,
  country      VARCHAR(50) NOT NULL,
  last_update  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (country_id)
);

CREATE TABLE city (
  city_id      SMALLINT    UNSIGNED NOT NULL AUTO_INCREMENT,
  city         VARCHAR(50) NOT NULL,
  country_id   SMALLINT    UNSIGNED NOT NULL,
  last_update  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (city_id),
  KEY idx_fk_country_id (country_id),
  CONSTRAINT fk_city_country FOREIGN KEY (country_id) REFERENCES country (country_id)
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE address (
  address_id   SMALLINT    UNSIGNED NOT NULL AUTO_INCREMENT,
  address      VARCHAR(50) NOT NULL,
  address2     VARCHAR(50) DEFAULT NULL,
  district     VARCHAR(20) NOT NULL,
  city_id      SMALLINT    UNSIGNED NOT NULL,
  postal_code  VARCHAR(10) DEFAULT NULL,
  phone        VARCHAR(20) NOT NULL,
  last_update  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (address_id),
  KEY idx_fk_city_id (city_id),
  CONSTRAINT fk_address_city FOREIGN KEY (city_id) REFERENCES city (city_id)
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE store (
  store_id          TINYINT    UNSIGNED NOT NULL AUTO_INCREMENT,
  manager_staff_id  TINYINT    UNSIGNED NOT NULL,
  address_id        SMALLINT   UNSIGNED NOT NULL,
  last_update       TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (store_id),
  UNIQUE KEY idx_unique_manager (manager_staff_id),  -- one manager manages only one store
  KEY idx_fk_address_id (address_id),
  -- CONSTRAINT fk_store_staff FOREIGN KEY (manager_staff_id) REFERENCES staff (staff_id) 
  -- ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_store_address FOREIGN KEY (address_id) REFERENCES address (address_id) 
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE inventory (
  inventory_id  MEDIUMINT  UNSIGNED NOT NULL AUTO_INCREMENT,
                           -- Simpler to use INT UNSIGNED
  film_id       SMALLINT   UNSIGNED NOT NULL,
  store_id      TINYINT    UNSIGNED NOT NULL,
  last_update   TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (inventory_id),
  KEY idx_fk_film_id (film_id),
  KEY idx_store_id_film_id (store_id, film_id),
  CONSTRAINT fk_inventory_store FOREIGN KEY (store_id) REFERENCES store (store_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inventory_film FOREIGN KEY (film_id) REFERENCES film (film_id) 
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE staff (
  staff_id     TINYINT     UNSIGNED NOT NULL AUTO_INCREMENT,
  first_name   VARCHAR(45) NOT NULL,
  last_name    VARCHAR(45) NOT NULL,
  address_id   SMALLINT    UNSIGNED NOT NULL,
  picture      BLOB        DEFAULT NULL,           -- Kept a picture as BLOB (up to 64KB)
  email        VARCHAR(50) DEFAULT NULL,
  store_id     TINYINT     UNSIGNED NOT NULL,
  active       BOOLEAN     NOT NULL DEFAULT TRUE,  -- BOOLEAN FALSE (0) TRUE (non-0)
  username     VARCHAR(16) NOT NULL,
  password     VARCHAR(40) BINARY DEFAULT NULL,    -- BINARY??
  last_update  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (staff_id),
  KEY idx_fk_store_id (store_id),
  KEY idx_fk_address_id (address_id),
  CONSTRAINT fk_staff_store FOREIGN KEY (store_id) REFERENCES store (store_id)
  ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_staff_address FOREIGN KEY (address_id) REFERENCES address (address_id)
  ON DELETE RESTRICT ON UPDATE CASCADE
);



CREATE TABLE customer (
  customer_id  SMALLINT    UNSIGNED NOT NULL AUTO_INCREMENT,
  store_id     TINYINT     UNSIGNED NOT NULL,
  first_name   VARCHAR(45) NOT NULL,
  last_name    VARCHAR(45) NOT NULL,
  email        VARCHAR(50) DEFAULT NULL,
  address_id   SMALLINT    UNSIGNED NOT NULL,
  active       BOOLEAN     NOT NULL DEFAULT TRUE,
  create_date  DATETIME    NOT NULL,
  last_update  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (customer_id),
  KEY idx_fk_store_id (store_id),
  KEY idx_fk_address_id (address_id),
  KEY idx_last_name (last_name),
  CONSTRAINT fk_customer_address FOREIGN KEY (address_id) REFERENCES address (address_id)
  ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_customer_store FOREIGN KEY (store_id) REFERENCES store (store_id)
  ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE rental (
  rental_id     INT        NOT NULL AUTO_INCREMENT,
  rental_date   DATETIME   NOT NULL,
  inventory_id  MEDIUMINT  UNSIGNED NOT NULL,
  customer_id   SMALLINT   UNSIGNED NOT NULL,
  return_date   DATETIME   DEFAULT NULL,
  staff_id      TINYINT    UNSIGNED NOT NULL,
  last_update   TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (rental_id),
  UNIQUE KEY  (rental_date, inventory_id, customer_id),
  KEY idx_fk_inventory_id (inventory_id),
  KEY idx_fk_customer_id (customer_id),
  KEY idx_fk_staff_id (staff_id),
   CONSTRAINT fk_rental_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id)
     ON DELETE RESTRICT ON UPDATE CASCADE,
   CONSTRAINT fk_rental_inventory FOREIGN KEY (inventory_id) REFERENCES inventory (inventory_id)
     ON DELETE RESTRICT ON UPDATE CASCADE,
   CONSTRAINT fk_rental_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
     ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE payment (
  payment_id    SMALLINT     UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id   SMALLINT     UNSIGNED NOT NULL,
  staff_id      TINYINT      UNSIGNED NOT NULL,
  rental_id     INT          DEFAULT NULL,
  amount        DECIMAL(5,2) NOT NULL,
  payment_date  DATETIME     NOT NULL,
  last_update   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY  (payment_id),
  KEY idx_fk_staff_id (staff_id),
  KEY idx_fk_customer_id (customer_id),
  CONSTRAINT fk_payment_rental FOREIGN KEY (rental_id) REFERENCES rental (rental_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_payment_customer FOREIGN KEY (customer_id) REFERENCES customer (customer_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_payment_staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

