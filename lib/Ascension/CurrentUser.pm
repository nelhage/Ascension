use warnings;
use strict;

=head1 NAME

Ascension::CurrentUser

=cut

package Ascension::CurrentUser;

use base qw(Jifty::CurrentUser);

sub is_superuser {
    my $self = shift;
    my $uobj = $self->user_object;
    return 1 if $uobj && $uobj->username eq 'nelhage';
    return $self->SUPER::is_superuser(@_);
}

=head1 SEE ALSO

Foo, Bar, Baz

=cut

1;
