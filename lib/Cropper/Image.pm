package Cropper::Image;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Imager;
__PACKAGE__->mk_accessors(qw(path image));
# Imagerのインスタンスを持つ 画像解析，インターフェイス提供

sub new_from_path {
    my ($class, $path) = @_;
    die "no path" unless defined $path;
    die "$path not exist" unless -f $path;
    $class->new({path => $path});
}

sub image {
    my ($self) = @_;
    return $self->{_image} if $self->{_image};

    my $image = Imager->new;
    $image->read(file => $self->path);#->filter(type => 'gaussian', stddev => 5);
    $self->{_image} = $image;
}

sub edge_left {
    my ($self) = @_;
    ($self->_edge_left_index - 0.5) * $self->split_width;
}

sub edge_right {
    my ($self) = @_;
    ($self->_edge_right_index + 1.5) * $self->split_width;
}

sub edge_top {
    my ($self) = @_;
    ($self->_edge_top_index - 0.5) * $self->split_height;
}

sub edge_bottom {
    my ($self) = @_;
    ($self->_edge_bottom_index + 1.5)* $self->split_height;
}

sub edge_center {
    my ($self) = @_;
    $self->_edge_center_index * $self->image->getwidth / $self->split_size;
}

sub _edge_left_index {
    my ($self) = @_;
    return $self->{_edge_left_index} if defined $self->{_edge_left_index};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    warn 'left';
    $self->{_edge_left_index} = $self->_find_edge([0..25], sub { my $i = shift; (width => $w / 50, left => $w * $i / 100, top => 0, height => $h) });
}

sub _edge_right_index {
    my ($self) = @_;
    return $self->{_edge_right_index} if defined $self->{_edge_right_index};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    warn 'right';
    $self->{_edge_right_index} = $self->_find_edge([reverse (75..99)], sub { my $i = shift; (width => $w / 50, left => $w * $i / 100, top => 0, height => $h) });
}

sub _edge_top_index {
    my ($self) = @_;
    return $self->{_edge_top_index} if defined $self->{_edge_top_index};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    warn 'top';
    $self->{_edge_top_index} = $self->_find_edge([0..25], sub { my $i = shift; (width => $w, left => 0, top => $h * $i / 100, height => $h / 50) });
}

sub _edge_bottom_index {
    my ($self) = @_;
    return $self->{_edge_bottom_index} if defined $self->{_edge_bottom_index};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    warn 'bottom';
    $self->{_edge_bottom_index} = $self->_find_edge([reverse (75..99)], sub { my $i = shift; (width => $w, left => 0, top => $h * $i / 100, height => $h / 50) });
}

sub _find_edge {
    my ($self, $range, $slice_position) = @_;

    my $on = undef;
    my $last = undef;
    my $eps = 0.001;
    my $sums = {-1 => 0};
    for my $i (@$range) {
        my $current = $self->_get_whiteness(&$slice_position($i));
        $last = $current unless $last;
        my $diff = abs($current - $last);
        if ($diff > $eps && !$on) {
            warn "on $i";
            $on = $i;
        } elsif ($diff <= $eps && $on) {
            $on = 0;
        }
        if ($on) {
            $sums->{$on} += $diff;
        }
        $last = $current;
    }

    my $first = -1;
    my $second = -1;
    for (keys %$sums) {
        if ($sums->{$_} > $sums->{$first}) {
            $second = $first;
            $first = $_;
        } elsif ($sums->{$_} > $sums->{$second}) {
            $second = $_;
        }
    }
    return $second if ($first < 2 && $second != -1);
    return $second if ($first > 97 && $second != -1);
    return $first;
}

# 真ん中限定で極小を探す 本当にcenterかどうかはcan_split_centerを見る必要がある
sub _edge_center_index {
    my ($self) = @_;
    return 50;
    return $self->{_edge_center_index} if defined $self->{_edge_center_index};
    my $diffs = $self->sums_x;
    my $res_index;
    for(my $i = int($self->split_size * 0.4); $i < $self->split_size * 0.6; $i++) { # 探索する範囲，てきとう
        $res_index ||= $i;
        if ($diffs->[$res_index] > $diffs->[$i]) {
            $res_index = $i;
        }
    }
    $self->{_edge_center_index} = $res_index;
}

sub can_split_center {
    my ($self) = @_;

    my $white = $self->_get_whiteness_x_at($self->_edge_center_index);
    $white < 0.1;               # 0.1以下なら切ってよさそう，てきとう
}

sub diffs_x {
    my ($self) = @_;
    return $self->{_diffs_x} if $self->{_diffs_x};
    my $sums = $self->sums_x;
    my $res = [];
    my $last;

    for my $i (@$sums) {
        $last = $i unless defined $last;
        push @$res, $i - $last;
        $last = $i;
    }
    $self->{_diffs_x} = $res;
}

sub _get_whiteness_x_at {
    my ($self, $index) = @_;
    $self->sums_x->[$index];
}

sub _get_whiteness_y_at {
    my ($self, $index) = @_;
    $self->sums_y->[$index];
}

# [{1 = white, 0 = black} x split_size]
sub sums_x {
    my ($self) = @_;
    return $self->{_sums_x} if $self->{_sums_x};
    my $w = $self->image->getwidth;
    my $h = $self->image->getheight;
    my $res = [];
    my $cut = 0.02;
    for my $i (0..$self->split_size - 1) {
        push @$res, $self->_get_whiteness(left=>$w * ($i / $self->split_size), top=>$h * $cut, width=>$w / $self->split_size, height=>$h * (1-$cut*2));
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
        push @$res, $i - $last;
        $last = $i;
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

    my $cut = 0.02;
    for my $i (0..$self->split_size - 1) {
        push @$res, $self->_get_whiteness(left=>$w * $cut, top=>$h * ($i / $self->split_size), width=>$w * (1-$cut*2), height=>$h / $self->split_size);
    }
    $self->{_sums_y} = $res;
}

# 黒線を検出くらいの細さになるはず
sub split_size {
    100;
}

sub split_width {
    my ($self) = @_;
    $self->image->getwidth / $self->split_size;
}

sub split_height {
    my ($self) = @_;
    $self->image->getheight / $self->split_size;
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


