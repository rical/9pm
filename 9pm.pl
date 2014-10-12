#!/usr/bin/perl
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use TAP::Harness;
use TAP::Parser::Aggregator;
use TAP::Formatter::Console;
use TAP::Formatter::Color;
use Data::Dumper;
use File::Basename;
use Getopt::Std;
use Cwd 'abs_path';
our $VERSION = "0.1";

# Do not continue to execute after Getopt help message is printed
$Getopt::Std::STANDARD_HELP_VERSION = 1;

# Define Getopt help message
sub HELP_MESSAGE() {
	print "usage: $0 [-d] [-v] [-c <config>] file...\n";
	print " -d           - debug\n";
	print " -c <config>  - configuration file\n";
	print " -v           - verbose\n";
}

sub is_suite {
	my($path) = @_;
	my($filename, $directories, $suffix) = fileparse($path, qr/\.[^.]*/);
	return $suffix eq ".yaml";
}

sub create_name {
	my($scope, $ns, $path, $name) = @_;

	if (not defined $name) {
		my($filename, $directories, $suffix) = fileparse($path, qr/\.[^.]*/);
		if (is_suite($path)) {
			$name = $filename;
		} else {
			$name = "$filename$suffix";
		}
	}

	if (defined $ns) {
		$name = "$ns/$name";
	}

	foreach my $tc (@{$scope}) {
		die "ERROR: '$name' already exists in scope" if ($tc->{'name'} eq $name);
	}

	return $name;
}

sub opt_translation($$) {
	my($opt, $path) = @_;
	my $base = dirname($path);

	$opt =~ s/<base>/$base/;

	return $opt;
}

sub load_case {
	my($scope, $ns, $path, $askname, $opts) = @_;
	if (defined $opts) {
		die "ERROR: case options ($opts) not in array format" if (not ref $opts eq 'ARRAY');
		foreach my $opt (@{$opts}) {
			$opt = opt_translation($opt, $path);
		}
	}
	my $name = create_name($scope, $ns, $path, $askname);
	return {'name' => $name, 'path' => $path, 'opts' => $opts};
}

sub load_suite {
	my($scope, $ns, $path, $name, $opts, $guard) = @_;
	my $nsname = create_name($scope, $ns, $path, $name);

	my @ret;
	for my $rec (@{LoadFile($path)}) {
		die "ERROR: no path specified for record\n".Dumper($rec) if (not defined $rec->{path});
		my $file = dirname($path)."/".$rec->{path};
		my @mopts = @{$opts};

		if (defined $rec->{opts}) {
			push(@mopts, @{$rec->{opts}});
		}

		push(@ret, load_path([(@{$scope}, @ret)], $nsname, $file, $rec->{name}, \@mopts, $guard));
	}
	return @ret;
}

sub load_path {
	my($scope, $ns, $path, $name, $opts, $guard) = @_;

	# TODO: propper cyclic detection
	die "ERROR: recursion guard hit (max 90)" if ($guard++ >= 90);

	die "ERROR: file '$path' not found" if (not -f $path);

	if (is_suite($path)) {
		return load_suite($scope, $ns, $path, $name, $opts, $guard);
	}

	return load_case($scope, $ns, $path, $name, $opts);
}

# Disable linebuffering
$|++;

# Parse options
my %options=();
exit 1 if not getopts("vdfc:", \%options);

# Always tell 9pm to output TAP
my @opts9pm = ('-t');

# Tell 9pm we wish to recive debug info
push(@opts9pm, '-d') if defined $options{d};

# Be verbose if -v or -d is set
my $verbose=0;
$verbose = 1 if (defined $options{v} or defined $options{d});

# Tell 9pm cases were it can find it's configuration file
if (defined $options{c}) {
	die "ERROR: Can not find configuration file: $options{c}" if (not -f  $options{c});
	push(@opts9pm, '-c', $options{c});
}

# Parse input files
my @tcs;
foreach my $arg (@ARGV) {
	push(@tcs, load_path(\@tcs, undef, $arg, undef, \@opts9pm, 0));
}

# Build arrays to pass to TAP::Harness
my @tests;
my %args;
foreach my $tc (@tcs) {
	push(@tests, [$tc->{path}, $tc->{name}]);
	$args{$tc->{name}} = $tc->{opts};
}

# Figure out if we want a JUnit capable harness
my $harness = TAP::Harness->new( {
		verbosity => $verbose,
		color => 1,
		test_args => \%args,
	} );

# $ENV{TCLLIBPATH} needs to be defined for our concatenation to work
$ENV{TCLLIBPATH} = "" if (not defined $ENV{"TCLLIBPATH"});
# Setup tcl library path and execute tests
$ENV{TCLLIBPATH} = dirname(abs_path($0))."/.. $ENV{TCLLIBPATH}";
$harness->runtests(@tests);
