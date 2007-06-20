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
        };
        with(class => 'stats'),
        row {
            cell { "Lowest level explored" };
            with(class => 'checkcell' .
                 ($_->has_ascended ? ' ascended' : '')),
                 cell { $_->lowest_dlvl } for (@users);
        };
        row {
            cell { "Highest XP level reached" };
            with(class => 'checkcell' .
                 ($_->has_ascended ? ' ascended' : '')),
                 cell { $_->highest_xlvl } for (@users);
        };
        row {
            cell { "Best AC attained" };
            with(class => 'checkcell' .
                 ($_->has_ascended ? ' ascended' : '')),
                 cell { $_->lowest_ac } for (@users);
        };
    };
    
};

template '/status' => page {
    my $user = get 'user';
    my $edit = get 'edit';
    my $milestones;
    my $action;
    
    h1 { "Status for " . $user->username . " (" . $user->name . ")" };
    if($edit) {
        hyperlink(url => '/user/' . $user->username, label => '[normal]');
    } elsif ($user->current_user_can('update')){
        hyperlink(url => '/user/' . $user->username . '/edit', label => '[edit]');
    }

    $milestones = $user->progress_milestones;

    form {
        render_region(name => 'stats',
                      force_path => 'stats_frag',
                      force_arguments => {user => $user->id, edit => $edit});
        
        with(style => 'clear:both'), div {};
        
        with(id => 'milestones'),
        div {
            h2 { "Milestones" };

            with (id => 'progress-milestones', class => 'milestone-table'),
            table {
                with (class => 'header'), row {
                    cell {$user->username . " has"};
                    cell {"...once"};
                    cell {"...consistently"};
                };
                while(my $um = $milestones->next) {
                    $action = Jifty->web->new_action(
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

        };

        with(id => 'other-achievements'),
        div {
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
                };
            };
        };
    }
};

template 'stats_frag' => sub {
    my $user = Ascension::Model::User->new;
    $user->load(get 'user');
    my $edit = get 'edit';
    my $action;
    
    with(id => 'stats'),
    div {
        $action = Jifty->web->new_action(class => 'UpdateUser', record => $user);
        h2 { "Stats" };
        my @extra_args = (render_mode => 'read');
        if($edit) {
            @extra_args = (render_mode => 'update');
        }
        with(class => 'inline'), div {
            render_param($action => 'lowest_ac', @extra_args);
            render_param($action => 'lowest_dlvl', @extra_args);
            render_param($action => 'highest_xlvl', @extra_args);
            if($edit) {
                form_submit(onclick => {submit => $action, refresh_self => 1},
                            label => 'Update');
            }
        }
    };
};

private template 'header' => sub {
    my ($title) = get_current_attr(qw(title));
    Jifty->handler->apache->content_type('text/html; charset=utf-8');
    head { 
        with(
            'http-equiv' => "content-type",
            content      => "text/html; charset=utf-8"
          ),    
          meta {};
        with( name => 'robots', content => 'all' ), meta {};
        with( rel  => 'shortcut icon',
              href => Jifty->web->url(path => '/static/images/at.ico'),
              type => 'image/vnd.microsoft.icon'
             ), link {};
        title { _($title) };
        Jifty->web->include_css;
        Jifty->web->include_javascript;
      };

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

use Jifty::View::Declare::CRUD;
for (qw(User Milestone UserMilestone)) {
    Jifty::View::Declare::CRUD->mount_view($_, undef, '/admin/' . (lc $_));
}

1;
