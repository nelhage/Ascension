use warnings;
use strict;

=head1 NAME

Ascension::View

=head1 DESCRIPTION

=cut

package Ascension::View;
use Jifty::View::Declare -base;

template '/' => page {
    my $ucol = Ascension::Model::UserCollection->new;
    my $milestones;
    my $um = Ascension::Model::UserMilestone->new;
    $ucol->limit(column => 'is_tracked', value => 1);
    my @users = @{$ucol->items_array_ref};

    h1 { "Nethack Summer of Ascension" };
    h2 {" All users' progress "};

    with (id => 'progress-milestones', class => 'all-table',
          cellspacing => ('0 but true'), cellpadding => ('0 but true')),
    table {
        with (class => 'header'), row {
            cell { "Milestone" };
            with(class => ($_->has_ascended ? 'ascended' : '')),
            cell { hyperlink(url => "/user/" . $_->username,
                             label => $_->username)
               } for (@users);
        };
        $milestones = Ascension::Model::MilestoneCollection->new;
        $milestones->limit(column => 'type', value => 'progress');
        $milestones->order_by(column => 'seq', order => 'ASC');
        while(my $m = $milestones->next) {
            row {
                cell {$m->description};
                for my $u (@users) {
                    my ($ok, $err) = $um->load_by_cols(who => $u, milestone => $m);

                    with(class => 'checkcell' .
                         ($u->has_ascended ? ' ascended' : '')), cell {
                        milemark($um, undef, undef, 'once');
                    }
                }
            };
        }
    };
    
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
                with(class => 'checkcell'), cell {
                    milemark($um, $action, $edit, 'once');
                };
                with(class => 'checkcell'), cell {
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
                with(class => 'checkcell'), cell {
                    milemark($um, $action, $edit, 'once');
                };
            };
        }
    };

    }
};

private template 'salutation' => sub {
    div {
    attr {id => "salutation" };
        if (    Jifty->web->current_user->id
            and Jifty->web->current_user->user_object )
        {
            _( 'Hiya, %1.', Jifty->web->current_user->username );
        }
        else {
            use URI;
            my $uri = URI->new(Jifty->web->url);
            $uri->scheme("https");
            $uri->port(444);
            $uri->path($ENV{PATH_INFO});
            outs(_("You're not currently signed in. "));
            hyperlink(url => $uri->as_string, label => 'Sign in');
            outs(_(" with your MIT certificates"));
        }
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
