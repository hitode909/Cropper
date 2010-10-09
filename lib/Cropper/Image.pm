package Cropper::Image;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
use Imager;
__PACKAGE__->mk_accessors(qw(path image));
# Imagerのインスタンスを持つ 画像解析，インターフェイス提供

sub new_from_path {
    my ($class, $path) = @_;
    $class->new({path => $path});
}

sub image {
    my ($self) = @_;
    return $self->{_image} if $self->{_image};

    my $image = Imager->new;
    $image->read(file => $self->path);
    $self->{_image} = $image;
}

sub analyze {
    my ($self) = @_;
}

1;


