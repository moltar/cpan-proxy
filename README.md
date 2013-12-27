# CPAN PROXY

This script runs an HTTP proxy that is designed to work with CPAN modules. It
will intercept any requests to download a tar.gz module package and save it
locally in cache. Later on, it will be accessible by `cpanm` and other tools.

## INSTALLATION

To get started, first of all, install all of the dependencies for this script:

    cpanm --installdeps .

Now start the daemon:

    ./cpan-proxy.pl start

Run `cpanm` via proxy:

    http_proxy=http://localhost:2726 cpanm My::Module

Run `carton` via proxy:

    http_proxy=http://localhost:2726 carton install

Note, that `http_proxy` environment variable is lowercase by design. It is an
accepted standard and used by [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent), `curl` and `wget`, which are
all of the available methods for `cpanm`.

## ENVIRONMENT

Cached module tarballs are stored in `$HOME/.cpan-cache` by default, but
that can be changed with `CPANM_CACHE` environmental variable.

You can also change the port number with `CPAN_PROXY_PORT` variable.

## TIPS

You can add the following to your `*rc` files to speed up the installs. This
will check local cache directories first, before issuing any remote requests:

    CPAN_CACHE="$HOME/.cpan-cache"
    export PERL_CPANM_OPT="--cascade-search --mirror=$CPAN_CACHE --mirror=http://search.cpan.org/CPAN"
    export PERL_CARTON_MIRROR="$CPAN_CACHE"

And to always use this proxy for your favorite tools, of course you can setup
an alias:

    alias cpanm='http_proxy=http://localhost:2726 cpanm'
