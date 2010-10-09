package test::Cropper;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use Test::More;
use Cropper;

sub init : Test(1) {
    new_ok 'Cropper';
}

sub new_from_path : Tests(3) {
    my $image = Cropper->new_from_path('t/file/good.jpg');
    ok $image;
    is $image->path, 't/file/good.jpg';

    isa_ok $image->image, 'Cropper::Image';
}

__PACKAGE__->runtests;

1;
