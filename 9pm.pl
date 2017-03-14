#!/usr/bin/perl
use strict;
use warnings;
use YAML::XS qw(LoadFile);
use TAP::Harness;
use TAP::Harness::JUnit;
use TAP::Parser::Aggregator;
use TAP::Formatter::Console;
use TAP::Formatter::Color;
use Data::Dumper;
use File::Basename;
use Getopt::Long qw(:config bundling ignore_case);
use Cwd 'abs_path';
our $VERSION = "0.1";

# Define Getopt help message
sub usage {
	my($rval) = @_;
	print "usage: $0 [options] file\n";
	print " --debug             - debug\n";
	print " --config <config>   - configuration file\n";
	print " --verbose           - verbose\n";
	print " --output <xmlfile>  - JUnit markup of run\n";
	print " --option <value>    - User-supplied value passed to file (multiple allowed)\n";
	exit $rval
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

print "Warning, this test executor is DEPRECATED, please migrate to 9pm.py\n";

# Disable linebuffering
$|++;

# Parse options
my %options=();
my @tcopts;
usage(1) if not GetOptions(\%options, "help|?|h" => sub { usage(0) },
	"debug|d", "config|c=s", "verbose|v", "output|o=s", "option|O=s" => \@tcopts);

# Always tell 9pm to output TAP
my @opts9pm = ('-t');

# Tell 9pm we wish to recive debug info
push(@opts9pm, '-d') if defined $options{debug};

# Be verbose if -v or -d is set
my $verbose=0;
$verbose = 1 if (defined $options{verbose} or defined $options{debug});

# Tell 9pm cases were it can find it's configuration file
if (defined $options{config}) {
	die "ERROR: Can not find configuration file: $options{config}" if (not -f  $options{config});
	push(@opts9pm, '-c', $options{config});
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
	# Put any user supplied options at the end
	push(@{$tc->{opts}}, @tcopts);
	$args{$tc->{name}} = $tc->{opts};
}

# Figure out if we want a JUnit capable harness
my $harness;
if (defined $options{output}) {
	$harness = TAP::Harness::JUnit->new( {
			verbosity => $verbose,
			color => 1,
			test_args => \%args,
			xmlfile => $options{output},
		} );
} else {
	$harness = TAP::Harness->new( {
			verbosity => $verbose,
			color => 1,
			test_args => \%args,
		} );
}

# $ENV{TCLLIBPATH} needs to be defined for our concatenation to work
$ENV{TCLLIBPATH} = "" if (not defined $ENV{"TCLLIBPATH"});
# Setup tcl library path and execute tests
$ENV{TCLLIBPATH} = dirname(abs_path($0))."/.. $ENV{TCLLIBPATH}";
$harness->runtests(@tests);
