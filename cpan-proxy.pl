#!/usr/bin/env perl

use warnings;
use strict;

use HTTP::Proxy qw();
use HTTP::Proxy::BodyFilter::simple qw();
use HTTP::Proxy::BodyFilter::save qw();
use File::Spec::Functions qw(tmpdir);
use Path::Tiny qw(path);
use Daemon::Control qw();

#--------------------------------------------------------------------------#
# defaults
#--------------------------------------------------------------------------#

my $CPANM_CACHE = $ENV{CPANM_CACHE} || path($ENV{HOME}, '.cpan-cache');
my $PORT = $ENV{CPAN_PROXY_PORT} || 2726;

#--------------------------------------------------------------------------#
# proxy
#--------------------------------------------------------------------------#

sub proxy {
    my $proxy = HTTP::Proxy->new(port => $PORT, via => q{});

    $proxy->push_filter(
        method  => 'GET',
        path    => qr{\.tar\.gz$},
        mime    => '*/*',
        request => HTTP::Proxy::BodyFilter::simple->new(
            sub {
                my ($self, $dataref, $message, $protocol, $buffer) = @_;

                my $head       = $message->as_string;
                my ($url)      = $head =~ m|GET (.+?)\s|;
                my ($filename) = $url =~ m|(authors/id/(.+?)\.tar\.gz)$|;
                my $file       = path($CPANM_CACHE, $filename);

                if ($file->exists) {
                    $proxy->response(
                        HTTP::Response->new(
                            200, 'OK', undef, $file->slurp_raw
                        ),
                    );
                } else {
                    $proxy->stash(filename => $file);
                }

                return 1;
            },
        ),
        response => HTTP::Proxy::BodyFilter::save->new(
            keep_old => 1,
            filename => sub {
                return $proxy->stash('filename');
            },
        ),
    );

    return $proxy;
}

#--------------------------------------------------------------------------#
# daemonization
#--------------------------------------------------------------------------#

Daemon::Control->new(
    {   name     => 'CPAN Proxy',
        path     => $0,
        program  => sub { proxy->start },
        fork     => 1,
        pid_file => path(tmpdir(), 'cpan-proxy.pid'),
    },
)->run;

#--------------------------------------------------------------------------#
# finish
#--------------------------------------------------------------------------#

1;
