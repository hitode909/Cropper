package test::Cropper::Image;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use Test::More;
use Test::Exception;
use Cropper;

sub _init : Test(1) {
    new_ok 'Cropper::Image';
}

sub _not_found : Test(1) {
    dies_ok {
        Cropper::Image->new_from_path('not_found');
    };
}

sub _new_from_path : Test(2) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    ok $image;
    isa_ok $image->image, 'Imager';
}

sub _edge_center : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is $image->edge_center, 2437;
}

sub _sums_x : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->sums_x}, $image->_split_size;
}

sub _diffs_x : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->diffs_x}, $image->_split_size;
}

sub _sums_y : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->sums_y}, $image->_split_size;
}

sub _diffs_y : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->diffs_y}, $image->_split_size;
}

__PACKAGE__->runtests;

1;
