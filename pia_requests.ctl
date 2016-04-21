LOAD DATA
APPEND
INTO TABLE vger_support.pia_request
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
  request_id            TERMINATED BY '|',
  request_date          DATE "YYYY-MM-DD HH24:MI:ss"    TERMINATED BY '|',
  user_field_1          TERMINATED BY '|',
  user_field_2          TERMINATED BY '|',
  user_field_3          TERMINATED BY '|',
  user_field_4          TERMINATED BY '|',
  user_field_5          TERMINATED BY '|',
  user_field_6          TERMINATED BY '|',
  bib_id                TERMINATED BY '|',
  title_brief           TERMINATED BY '|',
  title_full            TERMINATED BY '|',
  author                TERMINATED BY '|',
  edition               TERMINATED BY '|',
  mfhd_id               TERMINATED BY '|',
  patron_last_name      TERMINATED BY '|',
  patron_first_name     TERMINATED BY '|',
  patron_barcode        TERMINATED BY '|',
  patron_group          TERMINATED BY '|',
  patron_code           TERMINATED BY '|',
  user_comment          TERMINATED BY '|',
  patron_id
)
