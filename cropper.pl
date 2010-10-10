#! /usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Cropper;
use Perl6::Say;
use File::Find::Rule;
use Path::Class;
use File::Basename;

unless (@ARGV) {
    say "usage: perl cropper.pl (jpgが入ったディレクトリ)";
    exit 1;
}

for my $input_dir (@ARGV) {
    my $output_dir = $input_dir . '_crop';
    mkdir($output_dir);
    my @input_files = File::Find::Rule->file->name('*.jpg')->in($input_dir);
    for my $input_file (@input_files) {
        my $in_page = 0;
        for my $page (Cropper->new_from_path($input_file)->pages) {
            my $output_filename = basename($input_file);
            $output_filename =~ s/\.jpg/_${in_page}.jpg/;
            say file($output_dir, $output_filename);
            $page->write(file => file($output_dir, $output_filename ));
            $in_page++;
        }
    }
}
