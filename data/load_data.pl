#!/usr/bin/perl

use strict;

use File::Basename;
use YAML;
use TokyoCabinet;

my $DB = 'hosttag.tch';

my $data_dir = dirname($0) . "/data";
die "Cannot find data dir '$data_dir'" unless -d $data_dir;

my %tag = ();

# Load all data
for my $host_dir (glob("$data_dir/*")) {
  next if $host_dir eq '.' || $host_dir eq '..';
  my $host = basename $host_dir;
  
  for my $tag_file (glob("$host_dir/*")) {
    $tag{ $host } ||= [];
    push @{ $tag{ $host } }, basename( $tag_file );
  }
}

# Invert %tag to get %host hash
my %host = ();
for my $host (keys %tag) {
  for my $tag ( @{ $tag{$host} } ) {
    $host{ $tag } ||= [];
    push @{ $host{ $tag } }, $host;
  }
}

-f $DB  && unlink $DB;

# Write database
my $db = TokyoCabinet::HDB->new;
$db->open( $DB, $db->OWRITER | $db->OCREAT )
  or die "DB $DB open failed: " . $db->errmsg( $db->ecode );

for my $host (keys %tag) {
  $db->put("hosts/$host", join(' ', sort @{ $tag{$host} }) . "\n")
    or die "DB $DB put failed: " . $db->errmsg( $db->ecode );
}
for my $tag (keys %host) {
  $db->put("tags/$tag", join(' ', sort @{ $host{$tag} }) . "\n")
    or die "DB $DB put failed: " . $db->errmsg( $db->ecode );
}

$db->close
  or die "DB $DB close failed: " . $db->errmsg( $db->ecode );
