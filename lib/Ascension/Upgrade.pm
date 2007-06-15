use warnings;
use strict;

=head1 NAME

Ascension::Upgrade

=cut

package Ascension::Upgrade;

use base qw(Jifty::Upgrade);
use Jifty::Upgrade qw(since);

since '0.0.3' => sub {
    my $users = Ascension::Model::UserCollection->new;
    $users->unlimit;
    while(my $u = $users->next) {
        $u->set_is_tracked(1);
    }
};

=head1 SEE ALSO

Foo, Bar, Baz

=cut

1;
