package test::Cropper::Image;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use Test::More;
use Cropper;

sub init : Test(1) {
    new_ok 'Cropper::Image';
}

sub new_from_path : Test(2) {
    my $image = Cropper::Image->new_from_path('t/file/good.jpg');
    ok $image;
    isa_ok $image->image, 'Imager';
}

__PACKAGE__->runtests;

1;
