set linesize 30;

-- Tab-delimited output
select distinct
    bib_id
||  chr(9)
||  vendor_code
||  chr(9)
||  account_number
as line_data
from pia_valid_requests
;
