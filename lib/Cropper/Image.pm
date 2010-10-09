package Cropper::Image;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Imager;
__PACKAGE__->mk_accessors(qw(path image));
# Imagerのインスタンスを持つ 画像解析，インターフェイス提供

sub new_from_path {
    my ($class, $path) = @_;
    die "$path not exist" unless -f $path;
    $class->new({path => $path});
}

sub image {
    my ($self) = @_;
    return $self->{_image} if $self->{_image};

    my $image = Imager->new;
    $image->read(file => $self->path);
    $self->{_image} = $image;
}

sub edge_left {
}

sub edge_right {
}

sub edge_top {
}

sub edge_bottom {
}

sub edge_center {
    my ($self) = @_;
    $self->image->getwidth / 2;
}

# private

sub diffs_x {
    my ($self) = @_;
    return $self->{_diffs_x} if $self->{_diffs_x};
    my $sums = $self->sums_x;
    my $res = [];
    my $last = 0.5;

    for my $i (@$sums) {
        push @$res, $last - $i;
    }
    $self->{_diffs_x} = $res;
}

# [{1 = white, 0 = black} x split_size]
sub sums_x {
    my ($self) = @_;
    return $self->{_sums_x} if $self->{_sums_x};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    my $res = [];

    for my $i (0..$self->_split_size - 1) {
        my $cropped = $self->image->crop(left=>$w * ($i / $self->_split_size), top=>$h * 0.2, width=>$w / $self->_split_size, height=>$h * 0.6);
        my $all_usage = $cropped->getcolorusagehash;
        my $binary_usage = {
            $self->_black => 0,
            $self->_white => 0,
        };
        for (keys %$all_usage) {
            $binary_usage->{$self->_key_for_binary($_)} += $all_usage->{$_};
        }
        push @$res, $binary_usage->{$self->_white} / ($w * $h * 0.6 / $self->_split_size);
    }
    $self->{_sums_x} = $res;
}

sub diffs_y {
    my ($self) = @_;
    return $self->{_diffs_y} if $self->{_diffs_y};
    my $sums = $self->sums_y;
    my $res = [];
    my $last = 0.5;

    for my $i (@$sums) {
        push @$res, $last - $i;
    }
    $self->{_diffs_y} = $res;
}

# [{1 = white, 0 = black} x split_size]
sub sums_y {
    my ($self) = @_;
    return $self->{_sums_y} if $self->{_sums_y};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    my $res = [];

    for my $i (0..$self->_split_size - 1) {
        my $cropped = $self->image->crop(left=>$w * 0.2, top=>($i / $self->_split_size), width=>$w * 0.6, height=>$h / $self->_split_size);
        my $all_usage = $cropped->getcolorusagehash;
        my $binary_usage = {
            $self->_black => 0,
            $self->_white => 0,
        };
        for (keys %$all_usage) {
            $binary_usage->{$self->_key_for_binary($_)} += $all_usage->{$_};
        }
        push @$res, $binary_usage->{$self->_white} / ($w * $h * 0.6 / $self->_split_size);
    }
    $self->{_sums_y} = $res;
}

sub _split_size {
    50;
}

sub _key_for_binary {
    my ($self, $binary) = @_;
    $self->_is_white($binary) ? $self->_white : $self->_black;
}

sub _is_white {
    my ($self, $binary) = @_;
    unpack("C", $binary) > 127;
}

sub _white {
    pack("C", 0);
}

sub _black {
    pack("C", 255);
}

1;


