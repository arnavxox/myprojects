USE library;

CREATE TABLE category (
  id INT NOT NULL AUTO_INCREMENT,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  PRIMARY KEY (id)
);

CREATE TABLE author (
  id INT NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100),
  PRIMARY KEY (id)
);

CREATE TABLE book (
  id INT NOT NULL AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  author_id INT NOT NULL,
  category_id INT NOT NULL,
  publication_year YEAR NOT NULL CHECK (publication_year >= 1500),
  copies_owned INT NOT NULL CHECK (copies_owned >= 1),
  PRIMARY KEY (id),
  FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (category_id) REFERENCES category(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE member_status (
  id INT NOT NULL AUTO_INCREMENT,
  status_value VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY (id)
);

CREATE TABLE member (
  id INT NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100),
  joined_date DATE NOT NULL CHECK (joined_date >= '2000-01-01'),
  active_status_id INT,
  PRIMARY KEY (id),
  FOREIGN KEY (active_status_id) REFERENCES member_status(id) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE loan (
  id INT NOT NULL AUTO_INCREMENT,
  book_id INT NOT NULL,
  member_id INT NOT NULL,
  loan_date DATE NOT NULL,
  returned_date DATE,
  PRIMARY KEY (id),
  FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE ON UPDATE CASCADE,
  CHECK (loan_date <= returned_date)
);

CREATE TABLE fine (
  id INT NOT NULL AUTO_INCREMENT,
  member_id INT NOT NULL,
  loan_id INT NOT NULL,
  fine_date DATE NOT NULL,
  fine_amount DECIMAL(10,2) NOT NULL CHECK (fine_amount >= 0),
  PRIMARY KEY (id),
  FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (loan_id) REFERENCES loan(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE fine_payment (
  id INT NOT NULL AUTO_INCREMENT,
  member_id INT NOT NULL,
  payment_date DATE NOT NULL,
  payment_amount DECIMAL(10,2) NOT NULL CHECK (payment_amount >= 0),
  PRIMARY KEY (id),
  FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE reservation_status (
  id INT NOT NULL AUTO_INCREMENT,
  status_value VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY (id)
);

CREATE TABLE reservation (
  id INT NOT NULL AUTO_INCREMENT,
  book_id INT NOT NULL,
  member_id INT NOT NULL,
  reservation_date DATE NOT NULL,
  status_id INT NOT NULL,
  PRIMARY KEY (id),
  FOREIGN KEY (book_id) REFERENCES book(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (member_id) REFERENCES member(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (status_id) REFERENCES reservation_status(id) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE fine_payment
ADD COLUMN fine_id INT,
ADD FOREIGN KEY (fine_id) REFERENCES fine(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- basic queries 

-- total fine by member
SELECT member_id, SUM(fine_amount) AS total_fine FROM fine GROUP BY member_id;

-- function to automatically loan books 
DELIMITER //
CREATE PROCEDURE IssueLoan(IN bookID INT, IN memberID INT, IN loanDate DATE)
BEGIN
    INSERT INTO loan (book_id, member_id, loan_date) VALUES (bookID, memberID, loanDate);
END //
DELIMITER ;

SELECT b.title, l.loan_date
FROM loan l
JOIN book b ON l.book_id = b.id
WHERE l.member_id = [specific_member_id] AND l.returned_date IS NULL;

SELECT m.first_name, m.last_name, b.title, l.loan_date
FROM loan l
JOIN member m ON l.member_id = m.id
JOIN book b ON l.book_id = b.id
WHERE l.returned_date IS NULL AND l.loan_date < CURDATE();

SELECT m.first_name, m.last_name, SUM(f.fine_amount) AS total_fines
FROM member m
JOIN loan l ON m.id = l.member_id
JOIN fine f ON l.id = f.loan_id
WHERE m.id = [specific_member_id]
GROUP BY m.id;

SELECT r.reservation_date, m.first_name, m.last_name, rs.status_value
FROM reservation r
JOIN member m ON r.member_id = m.id
JOIN reservation_status rs ON r.status_id = rs.id
WHERE r.book_id = [specific_book_id] AND rs.status_value != 'Completed';

