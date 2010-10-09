package test::Cropper;
use strict;
use warnings;
use base qw(Test::Class);
use Path::Class;
use lib file(__FILE__)->dir->parent->subdir('lib')->stringify;
use Test::More;
use Test::Exception;
use Cropper;

sub _init : Test(1) {
    new_ok 'Cropper';
}

sub _new_from_path : Tests(3) {
    my $image = Cropper->new_from_path('t/file/binary.jpg');
    ok $image;
    is $image->path, 't/file/binary.jpg';

    isa_ok $image->image, 'Cropper::Image';
}

sub _not_found : Test(2) {
    dies_ok {
        Cropper->new_from_path('not_found');
    };
    dies_ok {
        Cropper->new_from_path;
    };

}



__PACKAGE__->runtests;

1;
