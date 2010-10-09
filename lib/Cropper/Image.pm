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
    $self->_edge_left_index * $self->split_width;
}

# sub _edge_left_index {
#     my ($self) = @_;
#     return $self->{_edge_left_index} if defined $self->{_edge_left_index};
#     my $diffs = $self->diffs_x;
#     my $res_index;
#     my $arrived_white = 0;
#     my $epsilon = 0.0004; # XXX
#     for(my $i = $self->split_size * 0.02; $i < $self->split_size * 0.5; $i++) { # 探索する範囲，てきとう
#         $res_index = $i;
#         if ($self->_get_whiteness_x_at($i) > 0.9) {
#             $arrived_white++;
#         }
#         if (abs($diffs->[$i]) > $epsilon) {
#             last if ($arrived_white);# > $self->split_size * 0.03);
#         }
#     }
#     $self->{_edge_left_index} = $res_index;
# }

# sub _edge_left_index {
#     my ($self) = @_;
#     return $self->{_edge_left_index} if defined $self->{_edge_left_index};
#     my $diffs = $self->diffs_x;
#     my $res_index;
#     my $arrived_white = 0;
#     my $did_reset = 0;
#     my $epsilon = 0.0001; # XXX
#     for(my $i = 0; $i < $self->split_size * 0.5; $i++) { # 探索する範囲，てきとう
#         $res_index = $i;
#         warn $self->_get_whiteness_x_at($i) . ", " . $diffs->[$i];
#         if (abs($diffs->[$i]) < 0.2 && $diffs->[$i] < -$epsilon && $arrived_white) {
#             warn 'down break';
#             last;
#         }
#         if ($self->_get_whiteness_x_at($i) > 0.8) { # 黒い枠を飛ばす
#             $arrived_white++;
#         } else {                # 白連続→灰色
#             warn "reset at $arrived_white" if $arrived_white > 0;
#             $arrived_white = 0;
#         }

#     }
#     $res_index-=1 if $res_index > 0;
#     $self->{_edge_left_index} = $res_index;
# }

sub _edge_left_index {
    my ($self) = @_;
    return $self->{_edge_left_index} if defined $self->{_edge_left_index};
    my $diffs = $self->diffs_x;
    my $best = {at => 0, score => 0};
    my $epsilon = 0.001; # XXX
    my $current_ok = 0;
    for(my $i = 0; $i < $self->split_size * 0.3; $i++) {
        #warn $i . "\t" . $self->_get_whiteness_x_at($i) . "\t" . $diffs->[$i];
        if ($self->_get_whiteness_x_at($i) > 0.9 && abs($diffs->[$i]) < $epsilon) {
            # warn "ok  " . $current_ok;
            $current_ok++;
        } else {
            if ($current_ok > $best->{score}) {
                warn "<reset at $i, score $current_ok";
                $best->{score} = $current_ok;
                $best->{at} = $i;
            }
            $current_ok = 0;
        }
    }
    $self->{_edge_left_index} = $best->{at};
}

sub _edge_right_index {
    my ($self) = @_;
    return $self->{_edge_right_index} if defined $self->{_edge_right_index};
    my $diffs = $self->diffs_x;
    my $best = {at => $self->split_size - 1, score => 0};
    my $epsilon = 0.001; # XXX
    my $current_ok = 0;
    warn 'R';
    for(my $i =  $self->split_size - 1; $i > $self->split_size * 0.7; $i--) {
        #warn $i . "\t" . $self->_get_whiteness_x_at($i) . "\t" . $diffs->[$i];
        if ($self->_get_whiteness_x_at($i) > 0.9 && abs($diffs->[$i]) < $epsilon) {
            # warn "ok  " . $current_ok;
            $current_ok++;
        } else {
            if ($current_ok > $best->{score}) {
                warn ">reset at $i, score $current_ok";
                $best->{score} = $current_ok;
                $best->{at} = $i;
            }
            $current_ok = 0;
        }
    }
    $self->{_edge_right_index} = $best->{at};
}

sub _edge_top_index {
    my ($self) = @_;
    return $self->{_edge_top_index} if defined $self->{_edge_top_index};
    my $diffs = $self->diffs_y;
    my $best = {at => $self->split_size - 1, score => 0};
    my $epsilon = 0.001; # XXX
    my $current_ok = 0;
    for(my $i = 0; $i < $self->split_size * 0.3; $i++) {
        # $warn $i . "\t" . $self->_get_whiteness_x_at($i) . "\t" . $diffs->[$i];
        if ($self->_get_whiteness_y_at($i) > 0.9 && abs($diffs->[$i]) < $epsilon) {
            # warn "ok  " . $current_ok;
            $current_ok++;
        } else {
            if ($current_ok > $best->{score}) {
                warn "^reset at $i, score $current_ok";
                $best->{score} = $current_ok;
                $best->{at} = $i;
            }
            $current_ok = 0;
        }
    }
    $self->{_edge_top_index} = $best->{at};
}

sub _edge_bottom_index {
    my ($self) = @_;
    return $self->{_edge_bottom_index} if defined $self->{_edge_bottom_index};
    my $diffs = $self->diffs_y;
    my $best = {at => 0, score => 0};
    my $epsilon = 0.001; # XXX
    my $current_ok = 0;
    for(my $i =  $self->split_size - 1; $i > $self->split_size * 0.7; $i--) {
        # warn $i . "\t" . $self->_get_whiteness_x_at($i) . "\t" . $diffs->[$i];
        if ($self->_get_whiteness_y_at($i) > 0.9 && abs($diffs->[$i]) < $epsilon) {
            # warn "ok  " . $current_ok;
            $current_ok++;
        } else {
            if ($current_ok > $best->{score}) {
                warn "vreset at $i, score $current_ok";
                $best->{score} = $current_ok;
                $best->{at} = $i;
            }
            $current_ok = 0;
        }
    }
    $self->{_edge_bottom_index} = $best->{at};
}

sub edge_right {
    my ($self) = @_;
    ($self->_edge_right_index + 1) * $self->split_width;
}

# sub _edge_right_index {
#     my ($self) = @_;
#     return $self->{_edge_right_index} if defined $self->{_edge_right_index};
#     my $diffs = $self->diffs_x;
#     my $res_index;
#     my $arrived_white = 0;
#     my $did_reset = 0;
#     my $epsilon = 0.0001; # XXX
#     warn 'R';
#     for(my $i = $self->split_size-1; $i > $self->split_size * 0.5; $i--) { # 探索する範囲，てきとう
#         $res_index = $i;
#         warn $self->_get_whiteness_x_at($i) . ", " . $diffs->[$i];
#         if (abs($diffs->[$i]) < 0.2 && $diffs->[$i] < -$epsilon && $arrived_white) {
#             warn 'down break';
#             last;
#         }
#         warn $self->_get_whiteness_x_at($i);
#         if ($self->_get_whiteness_x_at($i) > 0.8) { # 黒い枠を飛ばす
#             $arrived_white++;
#         } else {                # 白連続→灰色
#             warn "reset at $arrived_white" if $arrived_white > 0;
#             $arrived_white = 0;
#         }

#     }
#     $res_index+=1 if $res_index < $self->split_size-1;
#     $self->{_edge_right_index} = $res_index;
# }

sub edge_top {
    my ($self) = @_;
    $self->_edge_top_index * $self->split_height;
}

sub edge_bottom {
    my ($self) = @_;
    ($self->_edge_bottom_index - 1)* $self->split_height;
}

sub edge_center {
    my ($self) = @_;
    $self->_edge_center_index * $self->image->getwidth / $self->split_size;
}

# 真ん中限定で極小を探す 本当にcenterかどうかはcan_split_centerを見る必要がある
sub _edge_center_index {
    my ($self) = @_;
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
    200;
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


