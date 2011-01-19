#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );

use_ok 'Module::Package';

my $module = Module::Package->new(
    name => 'Module::Package',
    version_from => 'lib/Module/Package.pm',
    prereq_pm => {
        'Archive::Tar' => 0,
        'Cwd' => 0,
        'ExtUtils::Manifest' => 0,
        'File::Copy' => 0,
        'File::Copy::Recursive' => 0,
        'File::Path' => 0,
	'Moose' => 0,
	'MooseX::SemiAffordanceAccessor' => 0,
        'MooseX::StrictConstructor' => 0,
	'MooseX::Method::Signatures' => 0,
	'MooseX::Types' => 0,
        'String::Random' => 0,
    },
    abstract_from => 'lib/Module/Package.pm',
    author => 'Jeffrey Ray Hallock <jeffrey dot hallock at gmail dot com>',
    exclude => [ '*.komodoproject', '.komodotools', '.git' ],
);

ok $module, 'created module object';
is $module->name, 'Module::Package', 'name set';
is $module->version_from, 'lib/Module/Package.pm', 'version_from set';
is $module->abstract_from, 'lib/Module/Package.pm', 'abstract_from set';
is $module->author, 'Jeffrey Ray Hallock <jeffrey dot hallock at gmail dot com>', 'author set';
