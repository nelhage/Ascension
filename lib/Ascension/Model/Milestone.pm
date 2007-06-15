use strict;
use warnings;

package Ascension::Model::Milestone;
use Jifty::DBI::Schema;

use Ascension::Record schema {

    column description => type is 'text', hints are 'He/she has ...';
    column seq => type is 'int';
    column type => type is 'text', valid are qw(progress misc);

    column users =>
        refers_to Ascension::Model::UserMilestoneCollection by 'milestone';

};

sub since {'0.0.2'}

# Your model-specific methods go here.

sub _brief_description { 'description' }

sub after_create {
    my $self = shift;
    my $idref = shift;
    $self->load($$idref);
    my $users = Ascension::Model::UserCollection->new;
    $users->unlimit;
    while(my $u = $users->next) {
        my $um = Ascension::Model::UserMilestone->new();
        $um->create(who => $u, milestone => $self);
    }
}

sub current_user_can {
    my $self = shift;
    my $right = shift;
    
    return 1 if $right eq 'read';
    return 1 if $right eq 'create';

    return $self->SUPER::current_user_can($right, @_);
}

1;

