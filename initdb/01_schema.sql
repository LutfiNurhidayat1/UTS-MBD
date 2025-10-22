-- =========================================
-- SCHEMA SALAM (Sistem Akademik dan Layanan Akademik Mahasiswa)
-- =========================================

CREATE SCHEMA IF NOT EXISTS SALAM AUTHORIZATION postgres;

-- =========================================
-- TABEL MAHASISWAS
-- =========================================
CREATE TABLE IF NOT EXISTS SALAM.mahasiswas (
  id BIGSERIAL PRIMARY KEY,
  nim CHAR(10) NOT NULL,
  nama VARCHAR(120) NOT NULL,
  email VARCHAR(180) NOT NULL,
  angkatan INT NOT NULL,
  ipk NUMERIC(3,2) NOT NULL DEFAULT 0.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_mahasiswa_nim UNIQUE (nim),
  CONSTRAINT uq_mahasiswa_email UNIQUE (email),
  CONSTRAINT ck_nim_format CHECK (nim ~ '^[0-9]{10}$'),
  CONSTRAINT ck_ipk_range CHECK (ipk >= 0.00 AND ipk <= 4.00),
  CONSTRAINT ck_angkatan_range CHECK (angkatan BETWEEN 2018 AND 2030)
);

-- =========================================
-- FUNGSI UNTUK UPDATE KOLOM updated_at
-- =========================================
CREATE OR REPLACE FUNCTION SALAM.touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_touch_updated ON SALAM.mahasiswas;
CREATE TRIGGER trg_touch_updated
BEFORE UPDATE ON SALAM.mahasiswas
FOR EACH ROW EXECUTE FUNCTION SALAM.touch_updated_at();

-- =========================================
-- TABEL MATA KULIAH
-- =========================================
CREATE TABLE IF NOT EXISTS SALAM.mata_kuliah (
  id SERIAL PRIMARY KEY,
  kode CHAR(6) UNIQUE NOT NULL,
  nama VARCHAR(100) NOT NULL,
  sks INT CHECK (sks BETWEEN 1 AND 6)
);

-- =========================================
-- TABEL NILAI MAHASISWA
-- =========================================
CREATE TABLE IF NOT EXISTS SALAM.nilai_mahasiswa (
  id SERIAL PRIMARY KEY,
  mahasiswa_id BIGINT REFERENCES SALAM.mahasiswas(id) ON DELETE CASCADE,
  mata_kuliah_id INT REFERENCES SALAM.mata_kuliah(id) ON DELETE CASCADE,
  nilai NUMERIC(5,2) CHECK (nilai BETWEEN 0 AND 100),
  grade CHAR(2) GENERATED ALWAYS AS (
    CASE
      WHEN nilai >= 85 THEN 'A'
      WHEN nilai >= 70 THEN 'B'
      WHEN nilai >= 55 THEN 'C'
      WHEN nilai >= 40 THEN 'D'
      ELSE 'E'
    END
  ) STORED
);

-- =========================================
-- VIEW REKAP NILAI
-- =========================================
CREATE OR REPLACE VIEW SALAM.vw_rekap_nilai AS
SELECT
  m.nim,
  m.nama,
  mk.nama AS mata_kuliah,
  n.nilai,
  n.grade
FROM SALAM.nilai_mahasiswa n
JOIN SALAM.mahasiswas m ON n.mahasiswa_id = m.id
JOIN SALAM.mata_kuliah mk ON n.mata_kuliah_id = mk.id;

-- =========================================
-- TRIGGER UNTUK UPDATE OTOMATIS IPK
-- =========================================
CREATE OR REPLACE FUNCTION SALAM.update_ipk()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE SALAM.mahasiswas
  SET ipk = (
    SELECT ROUND(AVG(
      CASE
        WHEN nilai >= 85 THEN 4.00
        WHEN nilai >= 70 THEN 3.00
        WHEN nilai >= 55 THEN 2.00
        WHEN nilai >= 40 THEN 1.00
        ELSE 0.00
      END
    ), 2)
    FROM SALAM.nilai_mahasiswa WHERE mahasiswa_id = NEW.mahasiswa_id
  )
  WHERE id = NEW.mahasiswa_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_ipk ON SALAM.nilai_mahasiswa;
CREATE TRIGGER trg_update_ipk
AFTER INSERT OR UPDATE ON SALAM.nilai_mahasiswa
FOR EACH ROW EXECUTE FUNCTION SALAM.update_ipk();

-- =========================================
-- DATA AWAL
-- =========================================
INSERT INTO SALAM.mahasiswas (nim, nama, email, angkatan, ipk)
VALUES
('1237050020','Lutfi Nurhidayat','lutfi@gmail.com',2023,3.60),
('1237050021','Andi','andi@gmail.com',2022,3.30),
('1237050022','Budi','budi@gmail.com',2024,3.40);

INSERT INTO SALAM.mata_kuliah (kode, nama, sks)
VALUES
('IF1001','Basis Data',3),
('IF1002','Algoritma Pemrograman',4),
('IF1003','Jaringan Komputer',3);

INSERT INTO SALAM.nilai_mahasiswa (mahasiswa_id, mata_kuliah_id, nilai)
VALUES
(1,1,90.0),
(1,2,80.0),
(2,3,75.0),
(3,1,60.0);
