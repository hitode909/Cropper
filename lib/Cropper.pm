package Cropper;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(path));
use Cropper::Image;

sub new_from_path {
    my ($class, $path) = @_;
    die "$path not exist" unless -f $path;
    $class->new({path => $path});
}

sub image {
    my ($self) = @_;
    $self->{_image} ||= Cropper::Image->new_from_path($self->path);
}

1;
