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

sub _not_found : Test(2) {
    dies_ok {
        Cropper::Image->new_from_path('not_found');
    };
    dies_ok {
        Cropper::Image->new_from_path;
    };
}

sub _new_from_path : Test(2) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    ok $image;
    isa_ok $image->image, 'Imager';
}

sub _edge_center : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    ok $image->edge_center > 1900 && $image->edge_center < 2100;
}

sub _edge_left : Tests(5) {
    {
        my $image = Cropper::Image->new_from_path('t/file/gray.jpg');
        ok $image->edge_left > 300 && $image->edge_left < 600;
        warn $image->edge_left;
        my $crop = $image->image->crop(left => $image->edge_left, top => 0, width => 500, height => $image->image->getheight);
        $crop->write(file => 'gray.jpg');
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/illust.jpg');
        ok $image->edge_left > 150 && $image->edge_left < 300;
        warn $image->edge_left;
        my $crop = $image->image->crop(left => $image->edge_left, top => 0, width => 500, height => $image->image->getheight);
        $crop->write(file => 'illust.jpg');
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
        ok $image->edge_left > 300 && $image->edge_left < 600;
        warn $image->edge_left;
        my $crop = $image->image->crop(left => $image->edge_left, top => 0, width => 500, height => $image->image->getheight);
        $crop->write(file => 'binary.jpg');
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/binary_difficult.jpg');
        ok $image->edge_left > 300 && $image->edge_left < 600;
        warn $image->edge_left;
        my $crop = $image->image->crop(left => $image->edge_left, top => 0, width => 500, height => $image->image->getheight);
        $crop->write(file => 'binary_difficult.jpg');
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/binary_side_line.jpg');
        ok $image->edge_left > 900 && $image->edge_left < 1000;
        warn $image->edge_left;
        my $crop = $image->image->crop(left => $image->edge_left, top => 0, width => 500, height => $image->image->getheight);
        $crop->write(file => 'binary_side_line.jpg');
    }
}

sub _get_whiteness : Tests(2) {
    {
        my $image = Cropper::Image->new_from_path('t/file/white.jpg');
        ok $image->_get_whiteness(width => 10, height => 10, top => 0, left => 0) > 0.9;
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/black.jpg');
        ok $image->_get_whiteness(width => 10, height => 10, top => 0, left => 0) < 0.1;
    }
}

sub _can_split_center : Tests(3) {
    {
        my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
        ok $image->can_split_center, 'モノクロ画像，切っていい';
        # my $crop = $image->image->crop(left => $image->edge_center, top => 0, width => 50, height => $image->image->getheight);
        # $crop->write(file => 'binary.jpg');
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/gray.jpg');
        ok $image->can_split_center, 'グレイスケール，切っていい';
        # my $crop = $image->image->crop(left => $image->edge_center, top => 0, width => 50, height => $image->image->getheight);
        # $crop->write(file => 'gray.jpg');
    }

    {
        my $image = Cropper::Image->new_from_path('t/file/illust.jpg');
        ok ! $image->can_split_center, 'イラストページ，切っちゃだめ';
        # my $crop = $image->image->crop(left => $image->edge_center, top => 0, width => 50, height => $image->image->getheight);
        # $crop->write(file => 'illust.jpg');
    }

}

sub _sums_x : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->sums_x}, $image->split_size;
}

sub _diffs_x : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->diffs_x}, $image->split_size;
}

sub _sums_y : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->sums_y}, $image->split_size;
}

sub _diffs_y : Tests(1) {
    my $image = Cropper::Image->new_from_path('t/file/binary.jpg');
    is @{$image->diffs_y}, $image->split_size;
}

__PACKAGE__->runtests;

1;
