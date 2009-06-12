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

since '0.0.6' => sub {
    my $ms = Ascension::Model::MilestoneCollection->new;
    $ms->limit(column => 'seq', value => '200', operator => '>=');
    # $ms->limit(column => 'type', value => 'misc');

    while(my $m = $ms->next) {
        $m->as_superuser->set_type('conduct');
        $m->as_superuser->set_seq($m->seq - 200);
    }
};


=head1 SEE ALSO

Foo, Bar, Baz

=cut


1;
