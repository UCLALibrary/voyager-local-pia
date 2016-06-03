#!/m1/shared/bin/perl -w

# Input: MARC file of bib records extracted from Voyager 
# Output: New MARC file with modified bib records
# * Add 985 $a with patron information
# * Change 981 $c location code based on account in 982 $b
# Updates vger_support.pia_request table for bib records processed

use strict;
use DBI;
use lib "/usr/local/bin/voyager/perl";
use MARC::Batch;
use UCLA_Batch; #for UCLA_Batch::safenext to better handle data errors

my $inputfile = $ARGV[0];
my $outputfile = $ARGV[1];
my $schema = $ARGV[2];
my $password = $ARGV[3];

my $batch = MARC::Batch->new('USMARC', $inputfile);
$batch->strict_off();

# Extracted records are in UTF-8
open OUT, '>:utf8', $outputfile or die "Cannot open output file: $!\n";

# Make database connection
my $dsn = "dbi:Oracle:host=localhost;sid=VGER";
my $dbh = DBI->connect($dsn, $schema, $password);
$dbh->{AutoCommit} = 0;  # enable transactions, if possible

my $sql_select = "
  select
    patron_barcode || ' *** ' || user_comment
  from vger_support.pia_valid_requests
  where bib_id = ?
";
my $sql_update = "
  update vger_support.pia_request
  set request_status = 'ORDERED'
  where request_status = 'REQUESTED'
  and bib_id = ?
";
my $sth_select = $dbh->prepare($sql_select);
my $sth_update = $dbh->prepare($sql_update);

# Loop thru bib records, modifying each
while (my $bibrecord = UCLA_Batch::safenext($batch)) {
  # Get bib 001 (bib_id) and use it to look up patron info
  my $bib_id = $bibrecord->field('001')->data();
  # print "$bib_id\n"; # for debugging
  my $result = $sth_select->execute($bib_id) || die $sth_select->errstr;
  my @data = $sth_select->fetchrow_array();
  my $patron_info = 'For patron ' . $data[0];

  # Change (or add) 985 $a with patron info
  my $f985 = $bibrecord->field('985');
  if ($f985) {
    my $f985a = $f985->subfield('a');
    $patron_info = $f985a . ' *** ' . $patron_info if $f985a;
    $f985->update(a => $patron_info);
  }
  else {
    $f985 = MARC::Field->new('985', '', '', 'a', $patron_info);
    $bibrecord->append_fields($f985);
  }

  # Get 982 $b account, to determine target location
  my $f982 = $bibrecord->field('982');
  my $account = "599030"; # default YRL account
  if ($f982) {
    $account = $f982->subfield('b') if defined($f982->subfield('b'));
  }
  
  # Change (or add) location code in 981 $c based on account
  my $newloc = getLocForAccount($account);
  my $f981 = $bibrecord->field('981');
  if ($f981) {
    $f981->update(c => $newloc);
  }
  else {
    $f981 = MARC::Field->new('981', '', '', 'c', $newloc);
    $bibrecord->append_fields($f981);
  }

  # Write bib record
  print OUT $bibrecord->as_usmarc();

  # Update pia_request.request_status
  $sth_update->execute($bib_id) || die $sth_update->errstr;
  $dbh->commit;
}

# Clean up
$sth_select->finish();
$sth_update->finish();
$dbh->disconnect(); # for Oracle, apparently commits any open transactions
close OUT;
exit 0;

sub getLocForAccount {
  my $account = shift;
  my $loc = "yr"; # default
  for ($account) {
    # Vendor YBP, ucla general account
    if    (/^599030/) {$loc = "yr";}
    elsif (/^599031/) {$loc = "ar";}
    elsif (/^599032/) {$loc = "mgnbks";}
    elsif (/^599033/) {$loc = "mu";}
    elsif (/^599038/) {$loc = "mu";}
    elsif (/^599050/) {$loc = "yr";}
    elsif (/^599051/) {$loc = "ar";}
    elsif (/^118730/) {$loc = "bi";}
    elsif (/^118770/) {$loc = "bi";}
    elsif (/^814730/) {$loc = "sm";}
    elsif (/^814770/) {$loc = "sm";}
    # Vendor YBP, ucla law account
    elsif (/^174799/) {$loc = "lw";}
    # Vendor CIB
    elsif (/^CIB/) {$loc = "ea";}
  }
  return $loc;
}

