## Bioperl Test Harness Script for Modules
##
# CVS Version
# $Id$


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
## perl test harness expects the following output syntax only!
## 1..3
## ok 1  [not ok 1 (if test fails)]
## 2..3
## ok 2  [not ok 2 (if test fails)]
## 3..3
## ok 3  [not ok 3 (if test fails)]
##
## etc. etc. etc. (continue on for each tested function in the .t file)
#-----------------------------------------------------------------------


## We start with some black magic to print on failure.
BEGIN { $| = 1; print "1..4\n"; 
	use vars qw($loaded); }
END {print "not ok 1\n" unless $loaded;}

use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::DBLoader;
$loaded=1;
print "ok \n";    # 1st test passed, loaded needed modules

$conf{'mysqladmin'} = '/mysql/current/bin/mysqladmin';
$conf{'mysql'} = '/mysql/current/bin/mysql';
$conf{'user'}  = 'root';
$conf{'database'} = 'ensembl07';
$conf{'transcript'} = 'ENST00000020513';

if ( -e 't/trans_to_vc.conf' ) {
   print STDERR "Reading configuration from trans_to_vc.conf\n";
   open(C,"t/trans_to_vc.conf");
   while(<C>) {
       my ($key,$value) = split;
       $conf{$key} = $value;
   }
} else {
    print STDERR "Using default values\n";
    foreach $key ( keys %conf ) {
	print STDERR " $key $conf{$key}\n";
    }
    print STDERR "\nPlease use a file t/transf_to_vc.conf to alter these values if the test fails\nFile is written <key> <value> syntax\n\n";
}

my $dbtype = 'rdb';
my $host   = 'localhost';
my $port   = '410000';
my $dbname = $conf{'database'};
my $dbuser = $conf{'user'};
my $dbpass = undef;
my $module = 'Bio::EnsEMBL::DBSQL::Obj';

#Connect to local ensembl db
my $locator = "$module/host=$host;port=$port;dbname=$dbname;user=$dbuser;pass=$dbpass";
my $db =  Bio::EnsEMBL::DBLoader->new($locator);
my $gene_obj=Bio::EnsEMBL::DBSQL::Gene_Obj->new($db);
print "ok 2\n";

#Get Virtual Contig for this transcript
my $vc=$gene_obj->get_Virtual_Contig($conf{'transcript'},150000);
print "ok 3\n";
#$vc->_dump_map;

my $seq=$vc->virtual_primary_seq;
my $subseq=$seq->subseq(10,20);
print "Subseq is $subseq\n";
$vc->id;
my $length=$vc->length;
print STDERR "Length of contig is $length\n";
print "ok 4\n";
my ($rc,$rc_pos,$rc_strand)=$vc->raw_contig_position(4000,-1);
print STDERR "Got RawContig ".$rc->id." rc_pos=$rc_pos, rc_strand=$rc_strand\n";
			      
