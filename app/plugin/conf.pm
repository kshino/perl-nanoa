package plugin::conf;

use strict;
use warnings;
use utf8;

use base qw{ NanoA::Plugin };

sub NanoA::conf {
    my $self = shift;

    require YAML;
    $self->{stash}{plugin_conf} ||= YAML::Load(
        $self->config->prefs( $self->config->app_name )
    );

    my $conf = $self->{stash}{plugin_conf};

    return $conf if not @_;
    return $conf->{$_[0]} if @_ == 1;
    return undef;
}

1;

