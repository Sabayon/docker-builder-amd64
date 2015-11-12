#!/usr/bin/env perl

use Getopt::Long;


my $profile = $ENV{BUILDER_PROFILE} // 3;
my $jobs    = $ENV{BUILDER_JOBS}    // 1;
my $preserved_rebuild    = $ENV{PRESERVED_REBUILD}    // 0;
my @overlays;

GetOptions('layman|overlay:s{,}' => \@overlays);

if (@ARGV==0) {
	help();die();
}

$ENV{LC_ALL} = "en_US.UTF-8";    #here be dragons

sub package_deps {
    my $package = shift;
    my $depth   = shift // 1;
    my $atom    = shift // 0;
    return
        map { $_ =~ s/\[.*\]|\s//g; &atom($_) if $atom; $_ }
        qx/equery -C -q g --depth=$depth $package/;    #depth=0 it's all
}

sub depgraph {
    map { $_ =~ s/^.*\]|\:\:.*$|\s|\n//g;  $_ }
        grep {/\]/} qx/emerge -poq --color n @_/;
}

sub depgraph_atom {
    map { $_ =~ s/^.*\]|\:\:.*$|\s|\n//g; &atom($_); $_ } grep {/\]/}
        qx/emerge -poq --color n @_/;    #depth=0 it's all
}

# Input : complete gentoo package ($P)
sub atom { s/-[0-9]{1,}.*$//; }

sub say { print join( "\n", @_ ) . "\n"; }

sub help {
	say "-> You should feed me with something","","Examples:","", "\t$0 app-text/tree" , "\t$0 plasma-meta --layman kde","","**************************","", "You can supply multiple overlays as well: $0 plasma-meta --layman kde plab","";
}

say "************* IF YOU WANT TO SUPPLY ADDITIONAL ARGS TO EMERGE, pass to docker EMERGE_DEFAULT_OPTS env with your options *************";


if(@overlays>0){
	say "Overlay(s) to add";
	foreach my $overlay (@overlays){
		say "\t- $overlay";
	}
}

say "Installing:";

say "\t* ".$_ for @ARGV;

say "* Syncing stuff for you, if it's the first time, can take a while";

# Syncronizing portage configuration and adding overlays
system("echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen"); #be sure about that.
system("cd /etc/portage/;git checkout master; git pull");
system("echo 'y' | layman -f -a $_") for @overlays;

my $reponame="LocalOverlay";

# Setting up a local overlay if doesn't exists
if (!-f "/usr/local/portage/profiles/repo_name") {
    system("mkdir -p /usr/local/portage/{metadata,profiles}");
    system("echo 'LocalOverlay' > /usr/local/portage/profiles/repo_name");
    system("echo 'masters = gentoo' > /usr/local/portage/metadata/layout.conf");
    system("chown -R portage:portage /usr/local/portage");
} else {
    open FILE,"</usr/local/portage/profiles/repo_name";
    my @FILE=<FILE>;
    close FILE;
    chomp(@FILE);
    $reponame=$FILE[0];
}

qx{
echo '[$reponame]
location = /usr/local/portage
masters = gentoo
priority=9999
auto-sync = no' > /etc/portage/repos.conf/local.conf
}; # Declaring the repo and giving priority

# sync portage and overlays
system("layman -S;emerge --sync --quiet");


qx|eselect profile set $profile|;
qx{ls /usr/portage/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept}
    ;    #HAHA
system("equo up && equo u"); # Better don't be behind
qx|echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf|;    #just plain evil.


# Separating packages from args
#my @args;
#my @packages;
#foreach my $value (@ARGV) {
#    if ( $value =~ /^\-/ ) {
#        push( @args, $value );
#    }
#    else {
#        push( @packages, $value );
#    }
#}

my @packages = @ARGV;

#my @packages_deps = depgraph_atom(@packages);
#push(@packages_deps,depgraph(@packages));
#say "Installing those deps with equo",@packages_deps;
my @packages_deps;
foreach my $p (@packages){
        push(@packages_deps,package_deps($p,1,1));
        push(@packages_deps,package_deps($p,1,0));
}
@packages_deps =  grep { defined() and length() } @packages_deps; #cleaning
say "Installing those deps with equo", @packages_deps;

system("equo i $_") for @packages_deps;

say "* Ready to compile, finger crossed";

my $rt = system("emerge -j $jobs --buildpkg @packages");

if($preserved_rebuild){

	system("emerge -j $jobs --buildpkg \@preserved-rebuild");

}

exit($rt >> 8);
