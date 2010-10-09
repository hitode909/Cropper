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
    # だいたいわかってるから，極小を探すだけでよいのでは
    my ($self) = @_;
    return $self->{_edge_center} if defined $self->{_edge_center};
    my $diffs = $self->sums_x;
    my $res_index;
    for(my $i = int($self->split_size * 0.4); $i < $self->split_size * 0.6; $i++) {
        $res_index ||= $i;
        if ($diffs->[$res_index] > $diffs->[$i]) {
            $res_index = $i;
        }
    }
    $self->{_edge_center} = $res_index * $self->image->getwidth / $self->split_size;
}

sub _edge_center_index {
    # TODO: これを使うようにする
}

sub can_split_center {
    my ($self) = @_;

    my $h = $self->image->getheight;
    my $dx = $self->image->getwidth / $self->split_size;
    my $white = $self->_get_whiteness(left=>$self->edge_center, top=>$h * 0.2, width=> $dx, height=>$h * 0.6);
    $white < 0.1;
}

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

    for my $i (0..$self->split_size - 1) {
        push @$res, $self->_get_whiteness(left=>$w * ($i / $self->split_size), top=>$h * 0.2, width=>$w / $self->split_size, height=>$h * 0.6);
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

    for my $i (0..$self->split_size - 1) {
        my $cropped = $self->image->crop(left=>$w * 0.2, top=>($i / $self->split_size), width=>$w * 0.6, height=>$h / $self->split_size);
        my $all_usage = $cropped->getcolorusagehash;
        my $binary_usage = {
            $self->_black => 0,
            $self->_white => 0,
        };
        for (keys %$all_usage) {
            $binary_usage->{$self->_key_for_binary($_)} += $all_usage->{$_};
        }
        push @$res, $binary_usage->{$self->_white} / ($w * $h * 0.6 / $self->split_size);
    }
    $self->{_sums_y} = $res;
}

# 黒線を検出くらいの細さになるはず
sub split_size {
    200;
}

# private

sub _get_whiteness {
    my ($self, %args) = @_;
    my $cropped = $self->image->crop(%args);
    # $cropped->write(file => rand() . '.jpg');
    my $all_usage = $cropped->getcolorusagehash;
    my $binary_usage = {
        $self->_black => 0,
        $self->_white => 0,
    };
    for (keys %$all_usage) {
        $binary_usage->{$self->_key_for_binary($_)} += $all_usage->{$_};
    }
    $binary_usage->{$self->_white} / ($args{width} * $args{height});

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


