use strict;
use warnings;

package Ascension::Model::UserMilestone;
use Jifty::DBI::Schema;

use Ascension::Record schema {

    column who => refers_to Ascension::Model::User;
    column milestone => refers_to Ascension::Model::Milestone;

    column once => type is 'boolean',
        label is 'at least once',
        default is 0;
    
    column consistent => type is 'boolean' ,
        label is 'consistently',
        default is 0;

};

use Jifty::RightsFrom column => 'who';

sub since {'0.0.2'};

# Your model-specific methods go here.

1;

