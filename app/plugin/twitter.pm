package plugin::twitter;

use strict;
use warnings;
use utf8;

use base qw{ NanoA::Plugin };

our $VERSION   = '0.01';
our $STASH_KEY = __PACKAGE__;

sub NanoA::twitter_config {
    my $self = shift;
    my %conf = (
        consumer_key    => '',
        consumer_secret => '',
        oauth_urls      => { qw{
            request_token_url https://twitter.com/oauth/request_token
            authorization_url https://twitter.com/oauth/authorize
            access_token_url  https://twitter.com/oauth/access_token
        } },
        clientname => '',
        clientver  => '',
        clienturl  => '',
        ssl        => 1,
        access_token        => undef,
        access_token_secret => undef,
        @_,
    );

    my %access_token = (
        token  => delete $conf{access_token},
        secret => delete $conf{access_token_secret},
    );

    $self->{stash}{$STASH_KEY} = {
        api          => undef,
        config       => \%conf,
        access_token => \%access_token,
    };
}

sub NanoA::twitter_access_token {
    my $self                = shift;
    my $access_token        = shift;
    my $access_token_secret = shift;
    my $stash               = $self->{stash}{$STASH_KEY};

    $stash->{access_token} = {
        token  => $access_token,
        secret => $access_token_secret,
    };

    if( $stash->{api} ) {
        $stash->{api}->access_token( $access_token );
        $stash->{api}->access_token_secret( $access_token_secret );
    }
}

sub NanoA::twitter {
    my $self  = shift;
    my $stash = $self->{stash}{$STASH_KEY};
    my $api   = $stash->{api};

    if( not $api ) {
        require Net::Twitter::Lite;

        my $conf = $stash->{config} // {};
        $api = $stash->{api} = Net::Twitter::Lite->new( %$conf );
    }

    $api->access_token( $stash->{access_token}{token} );
    $api->access_token_secret( $stash->{access_token}{secret} );

    return $api;
}

sub NanoA::twitter_auth_url {
    my $self         = shift;
    my $callback_url = shift;
    my $session      = $self->session;
    my $api          = $self->twitter;

    my $url = $api->get_authorization_url(
        ( $callback_url ? ( callback => $callback_url ): () ),
    );

    $session->set( plugin_twitter_auth => {
        token        => $api->request_token,
        token_secret => $api->request_token_secret,
    } );

    return $url;
}

sub NanoA::twitter_callback {
    my $self     = shift;
    my $session  = $self->session;
    my $verifier = $self->query->param( 'oauth_verifier' );
    my $api      = $self->twitter;
    my $token    = $session->get( 'plugin_twitter_auth' ) || {};

    $session->remove( 'plugin_twitter_auth' );

    $api->request_token( $token->{token} );
    $api->request_token_secret( $token->{token_secret} );

    my %result;
    @result{ qw{ access_token access_token_secret user_id screen_name } }
        = $api->request_access_token( verifier => $verifier );

    return wantarray ? %result: \%result;
}

1;

