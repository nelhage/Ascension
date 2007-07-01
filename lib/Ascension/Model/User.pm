use strict;
use warnings;

package Ascension::Model::User;
use Jifty::DBI::Schema;

use Ascension::Record schema {

column username =>
    label is 'Username',
    hints is 'Athena username',
    is distinct, is mandatory;

column milestones =>
    refers_to Ascension::Model::UserMilestoneCollection by 'who';

column lowest_ac =>
    type is 'int',
    default is 10,
    label is 'Best AC achieved',
    since '0.0.4';

column lowest_dlvl =>
    type is 'int',
    default is 1,
    label is 'Lowest level explored',
    since '0.0.4';

column highest_xlvl =>
    type is 'int',
    default is 1,
    label is 'Highest XP level reached',
    since '0.0.4';

column best_death =>
    type is 'text',
    render_as 'textarea',
    label is 'Favorite dumb or amusing death',
    since '0.0.5';

column is_tracked =>
    type is 'boolean',
    default is 0,
    since '0.0.3';

};

sub since { '0.0.2' };

use Jifty::Plugin::User::Mixin::Model::User;

# Your model-specific methods go here.

sub validate_email {
    1;
}

sub remote_user {
    my $email = $ENV{SSL_CLIENT_S_DN_Email};
    return unless $email;
    my ($username) = $email =~ /^(.+)@/;
    my $user = Ascension::Model::User->new;
    my ($ok, $err) = $user->load_or_create(username => $username);
    die $err unless $ok;
    my $realname = $ENV{SSL_CLIENT_S_DN_CN};
    if($realname) {
        my ($ok, $err) = $user->as_superuser->set_name($realname);
        die $err unless $ok;
    }
    return $user;
}

sub before_create {
    my $self = shift;
    my $args = shift;

    my $username = $args->{username};
    $args->{email} = "$username\@mit.edu";
    $args->{email_confirmed} = 1;

    return 1;
}

sub after_create {
    my $self = shift;
    my $idref = shift;
    $self->load($$idref);
    my $milestones = Ascension::Model::MilestoneCollection->new;
    $milestones->unlimit;
    while(my $m = $milestones->next) {
        my $um = Ascension::Model::UserMilestone->new();
        $um->create(who => $self, milestone => $m);
    }
}

sub current_user_can {
    my $self = shift;
    my $right = shift;

    return 1 if $right eq 'read' || $right eq 'create';
    return 1 if $right eq 'update' && $self->id == $self->current_user->id;

    return $self->SUPER::current_user_can($right, @_);
}

sub progress_milestones {
    my $self = shift;
    return $self->_milestones('progress');
}

sub misc_milestones {
    my $self = shift;
    return $self->_milestones('misc');
}

sub _milestones {
    my $self = shift;
    my $type = shift;
    my $milestones = $self->milestones;
    my $alias = $milestones->join(
        alias1 => 'main',
        column1 => 'milestone',
        table2 => 'milestones',
        column2 => 'id');
    $milestones->limit(alias => $alias, column => 'type', value => $type);
    $milestones->order_by(alias => $alias, column => 'seq', order => 'ASC');
    return $milestones;
}

sub has_ascended {
    my $self = shift;
    my $milestone = Ascension::Model::Milestone->new();
    $milestone->load_by_cols(description => 'Ascended');
    my $um = Ascension::Model::UserMilestone->new();
    $um->load_by_cols(who => $self, milestone => $milestone);
    return $um->once;
}


1;

