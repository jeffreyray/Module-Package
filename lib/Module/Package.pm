package Module::Package;

our $VERSION = 0.03;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use MooseX::Types::Moose qw( Str HashRef );

use Archive::Tar;
use Cwd;
use ExtUtils::Manifest qw( mkmanifest );
use File::Copy qw( copy );
use File::Copy::Recursive qw( dircopy );
use File::Path qw( remove_tree );

use String::Random qw(random_regex);

has 'abstract_from' => (
    is => 'rw',
    isa => Str,
);

has 'author' => (
    is => 'rw',
    isa => Str,
);

has 'exclude' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

has 'name' => (
    is => 'rw',
    isa => Str,
);

has 'prereq_pm' => (
    is => 'rw',
    isa => HashRef,
    default => sub { { } },
);

has 'version_from' => (
    is => 'rw',
    isa => Str,
);




sub package {
    my ( $self, $path ) = @_;
    $path ||= '..';
    
    
    my $version = $self->_extract_version;
       
    my $name = $self->name;
    $name =~ s/::/-/g;
    my $package_string = $name . '-' . $version;
    
    my $tmpdir = random_regex( '[0-9A-Z]{8}-[0-9A-Z]{8}-[0-9A-Z]{8}-[0-9A-Z]{8}' );
    
    # copy the entire module directory into the temp directory
    dircopy( '.', qq[$path/$tmpdir/$package_string] );
    
    my $cwd = getcwd;
    chdir qq[$path/$tmpdir/$package_string];
    
    # remove the excluded files
    for my $pattern ( @{ $self->exclude } ) {
        for my $file ( glob $pattern ) {
            
            # delete entire directory if it is one
            if ( -d $file ) {
                remove_tree( $file );
            }
            else {
                unlink $file;
            }
        }
    }
    
    # delete the calling script (Package.PL)
    unlink $0;
    
    
    # create the makefile
    $self->_write_makefile;
   
    # create the manifest
    mkmanifest();
    
    # archive the files
    chdir '..';
    
    
    print "archiving $package_string";
    system(qq[tar -cf $package_string.tar $package_string]);
    system(qq[gzip $package_string.tar]);
    
    # copy the file to the output dir
    chdir $cwd;
    copy( qq[$path/$tmpdir/$package_string.tar.gz], qq[$path/$package_string.tar.gz] );
    
    # clean up the temporary files
    remove_tree( qq[$path/$tmpdir] );
}

sub _extract_version {
    my ( $self ) = @_;
    my $name = $self->name;
    
    my $version_from = $self->version_from;
    
    my ( $path, $file ) = 
    $version_from =~ /(.*?)\/(.*)/ ?
    ( $1, $2 ) :
    ( 'lib', $version_from );
    
    require $version_from;
    
    my $version;
    eval qq[
        \$version = \$${name}::VERSION;
    ];
    
    confess qq( could not load $version_from $@) if $@;
    confess qq( could not find ${name}::VERSION in $version_from ) if ! defined $version;
    
    return $version;
}

sub _write_makefile ( ) {
    my ( $self ) = @_;
    open my $MAKEFILE, '>Makefile.PL'
        or die "could not open Makefile.PL for writing";
    flock $MAKEFILE, 2;
    
print $MAKEFILE <<END_MAKEFILE;
use 5.010000;
use ExtUtils::MakeMaker;


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
END_MAKEFILE

    print $MAKEFILE qq[NAME => '] . $self->name . qq[',\n];
    print $MAKEFILE qq[VERSION_FROM => '] . $self->version_from . qq[',\n];
    
    print $MAKEFILE qq[PREREQ_PM => {\n];
    for my $key ( sort keys %{$self->prereq_pm} ) {
        print $MAKEFILE qq[\t'$key' => ] . $self->prereq_pm->{$key} . qq[,\n];
    }
    print $MAKEFILE qq[},\n];
    
    print $MAKEFILE qq[($\] >= 5.005 ?     ## Add these new keywords supported since 5.005\n];
    print $MAKEFILE qq[   (ABSTRACT_FROM  => '] . $self->abstract_from . qq[', # retrieve abstract from module\n];
    print $MAKEFILE qq[    AUTHOR         => '] . $self->author . qq[') : ()),\n];    
    print $MAKEFILE qq[);\n];
    close $MAKEFILE;
}

1;


__END__

=head1 NAME

Module::Package - Helper for packaging modules

=head1 SYNOPSIS

  use Module::Package;

  my $module = Module::Package->new(

    name => 'Foo::Bar',

    version_from => 'lib/Foo/Bar.pm',

    prereq_pm => {

      'Moose' => 0,

    },

    abstract_from => 'lib/Foo/Bar.pm',

    author => 'Jeffrey Ray Hallock <jeffrey dot hallock at gmail dot com>',

    exclude => [ '.git' ],

  );

  $module->pack;
  
=head1 DESCRIPTION

L<Module::Package> aids in the process of packaging a perl module for release.
L<Module::Package> can:

=over 4

=item create a MANIFEST

=item create a Makefile.PL

=item create an .tar.gz file for distribution

=back

=head2 ATTRIBUTES

Most of these attributes (unless otherwise mentioned) are used when creating
the C<Makefile.PL> script. See <ExtUtils::MakeMaker> for more details.

=over 4

=item abstract_from

Str

=item author

Str

=item exclude

ArrayRef

A list of file globs that will not be included in the library when it is
packaged. Use this to exclude things like your C<.git> directory or other
development only files.

=item name

=item prereq_pm

=item version_from

=back

=head2 METHODS

=over 4

=item package $dir ?

Packages the module for distribution and saves it as module-name-x.xx.tar.gaz
in the given C<$dir>. If no directory is supplied, defaults to C<..>.

Packaging for distribution means:

=over 4

=item Copying module files to a temporary directory

=item Removing the excluded files

=item Creating the MANFIEST file

=item Creating the Package.pl file

=item Creating an archive for distribution

=item Saving the archive to C<$dir>

=item Cleaning up temporary files

=back

=back

=head1 LIMITATIONS

L<Module::Package> is a simple module for packaging other simple modules.  This
module may not be suitable for you if you need to customize your Makefile.pl
more than L<Module::Package> allows. If you think a feature should be included,
feel free to code it and submit a patch to the author. Alternatively, you could
contact the author and request that the feature be implemented.

=head1 BUGS

All software has bugs. If you find any in this software, please send them to
<jeffrey.hallock at gmail dot com>. Patches and suggestions welcome.

=head1 AUTHOR

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT

    Copyright (c) 2010-2011 Jeffrey Ray Hallock. All rights reserved.
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut



