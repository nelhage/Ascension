package Ascension::Dispatcher;

use Jifty::Dispatcher -base;

before '*' => run {
    if(!Jifty->web->current_user->id) {
        my $user = Ascension::Model::User->remote_user;
        if($user) {
            Jifty->web->temporary_current_user(
                Ascension::CurrentUser->new(username => $user->username));
        }
    }
};

before '/user/**' => run {
    my $nav = Jifty->web->navigation;
    my $ucol = Ascension::Model::UserCollection->new;
    $ucol->limit(column => 'is_tracked', value => 1);
    while(my $u = $ucol->next) {
        $nav->child($u->username,
                   label => $u->username,
                   url => "/user/" . $u->username);
    }
};

before qr{^/admin} => run {
    redirect '/' unless Jifty->web->current_user->is_superuser;
};

on qr{^/user/([^/]+)(/edit|)$} => run {
    my $username = $1;
    my $user = Ascension::Model::User->new;
    my $edit = $2;
    $user->load_by_cols(username => $username);
    if(!$user || !$user->is_tracked) {
        redirect '/errors/no_such_user';
    }
    if($edit && !$user->current_user_can('update')) {
        redirect "/user/$username";
    }
    set user => $user;
    set edit => $edit;
    show '/status';
    
};

1;
