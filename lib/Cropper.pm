package Cropper;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(path));
use Cropper::Image;

sub new_from_path {
    my ($class, $path) = @_;
    die "no path" unless defined $path;
    die "$path not exist" unless -f $path;
    $class->new({path => $path});
}

# クロップして返す 1か2ページ
sub pages {
    my ($self) = @_;

    my $image = $self->image;
    if ($image->can_split_center) {
        (
            $image->crop(width => $image->edge_right - $image->edge_center, height => $image->edge_bottom - $image->edge_top, left => $image->edge_center, top => $image->edge_top),
            $image->crop(width => $image->edge_center - $image->edge_left, height => $image->edge_bottom - $image->edge_top, left => $image->edge_left, top => $image->edge_top),
        );
    } else {
        (
            $image->crop(width => $image->edge_right - $image->edge_left, height => $image->edge_bottom - $image->edge_top, left => $image->edge_left, top => $image->edge_top)
        );
    }
}

sub image {
    my ($self) = @_;
    $self->{_image} ||= Cropper::Image->new_from_path($self->path);
}

1;
