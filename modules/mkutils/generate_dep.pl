#!/usr/bin/perl

use strict;
use warnings;

# Vérifiez que l'utilisateur a fourni les arguments nécessaires

my $source_file;
my $obj_file;
my $mk_file;

if (@ARGV == 3) {
    ($source_file, $obj_file, $mk_file) = @ARGV;
} elsif (@ARGV == 2) {
    ($source_file, $mk_file) = @ARGV;
    $obj_file = $source_file;
} else {
    die "Usage: $0 <source_file> <obj_file> <mk_file>\n";
}

$source_file = convert_path($source_file);
$obj_file = convert_path($obj_file);
$mk_file = convert_path($mk_file);

# Ouvrir le fichier source pour lecture
open my $src_fh, '<', $source_file or die "Impossible d'ouvrir le fichier source $source_file: $!\n";

# Ouvrir le fichier Makefile pour écriture
open my $mk_fh, '>', $mk_file or die "Impossible d'ouvrir le fichier Makefile $mk_file: $!\n";

if (@ARGV == 3) {
    print $mk_fh "$obj_file: $source_file\n";
}

# Parcourir le fichier source ligne par ligne
while (my $line = <$src_fh>) {
    # Règle spéciale pour vwf
	if($line =~ /^\s*font\s*(?:[^\s]*)\s*,\s*([^\s]*)\s*/i) {
        my $file = $1;
        my $file2 = "${1}len";

        print $mk_fh "$obj_file: $file $file2\n";
        print $mk_fh "$file:\n";
        print $mk_fh "$file2:\n";
    }

    # Rechercher les lignes avec include("fichier") ou incbin("fichier") ou using("fichier")
    if ($line =~ /^\s*(?:(?:include|incbin|using)\s+(?:"([^"]*)"|\("([^"]*)"\))|(?:include|incbin|using)\((?:"([^"])*")\))\s*$/i) {
        my $file = $1;

        if ($file =~ /\{(?:[^\}]+)\}/i) {
            $file = "\$$file";
        }

        print $mk_fh "$obj_file: $file\n";
        print $mk_fh "$file:\n";
    }
}

if ($obj_file =~ /.o$/) {
    print $mk_fh "OBJS+= $obj_file";
}

# Fermer les fichiers
close $src_fh;
close $mk_fh;

sub convert_path {
    my ($win_path) = @_;

    # Remove the starting '.\' or '.\'
    $win_path =~ s/^\.\\//;

    # Replace backslashes with forward slashes
    $win_path =~ s/\\/\//g;

    return $win_path;
} 

