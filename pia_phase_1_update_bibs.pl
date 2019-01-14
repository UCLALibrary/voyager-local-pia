#!/m1/shared/bin/perl -w

# Takes file of bib records and inserts an 852 field in each record.
# Discard serial records.

use strict;
use lib "/usr/local/bin/voyager/perl";
use MARC::Batch;
use UCLA_Batch; #for UCLA_Batch::safenext to better handle data errors

# 3 required arguments
if ($#ARGV != 2) {
  print "\nUsage: $0 vendorcode infile outfile\n";
  exit 1;
}

my $vendorcode = $ARGV[0];
my $inputfile = $ARGV[1];
my $outputfile = $ARGV[2];
my $batch = MARC::Batch->new('USMARC', $inputfile);
$batch->strict_off();

# YBP and CIB PIA records are now in UTF-8
open OUT, '>:utf8', $outputfile or die "Cannot open output file: $!\n";

# Create constant 852 with info we need for all records
my $f852 = MARC::Field->new('852', '', '', b=>'pdacq');
my $f852h = 'UCLA faculty and students ONLY: Click on "Request an Item" and select "Buy this item-Purchase Request" to ask Library to order this';
$f852->add_subfields('h', $f852h);

# Loop thru bib records, inserting data in each
while (my $bibrecord = UCLA_Batch::safenext($batch)) {

  # Discard (skip) serial records - they will not be written to output file
  my $bib_lvl = substr($bibrecord->leader(), 7, 1);
  if ($bib_lvl eq 's') {
    next;
  }

  # Strip fields with bad data which make bulkimport crash
  # 336 $b must be 3 chars
  my @f336s = $bibrecord->field('336');
  foreach my $f336 (@f336s) {
    my $f336b = $f336->subfield('b');
    if ($f336b && length($f336b) != 3) {
      $bibrecord->delete_field($f336);
    }
  }

  # 338 $b must be 2 chars
  my @f338s = $bibrecord->field('338');
  foreach my $f338 (@f338s) {
    my $f338b = $f338->subfield('b');
    if ($f338b && length($f338b) != 2) {
      $bibrecord->delete_field($f338);
    }
  }

  # Add constant 852
  $bibrecord->insert_fields_ordered($f852);

  # Add 982 with vendor info: $a vendorcode $b account
  # If no 982 $b account provided, use vendorcode
  my $account = $vendorcode;
  my $f982 = $bibrecord->field('982');
  # If 982 exists, Capture account info if present, then delete 982
  if ($f982) {
    $account = $f982->subfield('b') if defined($f982->subfield('b'));
    $bibrecord->delete_field($f982);
  }
  # Create new 982
  $f982 = MARC::Field->new('982', '', '', a=>$vendorcode, b=>$account);
  $bibrecord->insert_fields_ordered($f982);

  # Write each bib record to the output file
  print OUT $bibrecord->as_usmarc();

}
close OUT;
exit 0;

