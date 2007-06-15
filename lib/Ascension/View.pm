use warnings;
use strict;

=head1 NAME

Ascension::View

=head1 DESCRIPTION

=cut

package Ascension::View;
use Jifty::View::Declare -base;

template '/' => page {
    h1 { "Nethack Summer of Ascension" };
    my $ucol = Ascension::Model::User::Collection->new;
    $ucol->unlimit;
    
};

template '/status' => page {
    my $user = get 'user';
    my $edit = get 'edit';
    my $milestones;

    
    h1 { "Status for " . $user->username . " (" . $user->name . ")" };
    if($edit) {
        hyperlink(url => '/user/' . $user->username, label => '[normal]');
    } elsif ($user->current_user_can('update')){
        hyperlink(url => '/user/' . $user->username . '/edit', label => '[edit]');
    }
    h2 { "Milestones" };

    $milestones = $user->progress_milestones;

    form {
    with (id => 'progress-milestones', class => 'milestone-table'),
    table {
        with (class => 'header'), row {
            cell {$user->username . " has"};
            cell {"...once"};
            cell {"...consistently"};
        };
        while(my $um = $milestones->next) {
            my $action = Jifty->web->new_action(
                class => 'UpdateUserMilestone',
                record => $um);
            row {
                cell { $um->milestone->description };
                cell {
                    milemark($um, $action, $edit, 'once');
                };
                cell {
                    milemark($um, $action, $edit, 'consistent');
                }
            };
        }
    };

    h2 { "Other achievements" };

    $milestones = $user->misc_milestones;
    
    with (id => 'misc-milestones', class => 'milestone-table'),
    table {
        with (class => 'header'), row {
            cell {$user->username . " has"};
            cell {};
        };
        while(my $um = $milestones->next) {
            my $action = Jifty->web->new_action(
                class => 'UpdateUserMilestone',
                record => $um);
            row {
                cell { $um->milestone->description };
                cell {
                    milemark($um, $action, $edit, 'once');
                };
            };
        }
    };

    }
};


sub milemark {
    my $um = shift;
    my $action = shift;
    my $edit = shift;
    my $column = shift;
    if(!$edit) {
        with (type => 'checkbox',
              ($um->$column ? (checked => 1) : ()),
              disabled => 1), input {};
    } else {
        with (class => "inline"), div {
            $action->form_field($column,
                onclick => {submit => $action, disable => 0},
                label => "");
        }
    }
}

1;
