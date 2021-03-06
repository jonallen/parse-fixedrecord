package Parse::FixedRecord::Row;

=head1 NAME

Parse::FixedRecord::Row - Row class for Parse::FixedRecord

=head1 DESCRIPTION

This is the base class for fixed record parsers.
Provides the C<parse> implementation.

=head2 Methods

=head3 C<parse>

See L<Parse::FixedRecord> for usage;

=head3 C<output>

Provides stringified output.  This is overloaded, so you can just:

    print $obj;

to get an output (in the same format as declared/parsed).  This depends
on each individual parser type having well behaved String overloading!

=head2 Types

::Row declares C<Duration> and C<DateTime> types for you to use in your
parsers.

=head1 AUTHOR and LICENSE

    osfameron@cpan.org - see Parse::FixedRecord for full details

=cut

use Parse::FixedRecord;
use Parse::FixedRecord::Column;

use MooseX::ClassAttribute;
use Moose::Util::TypeConstraints;
use DateTime::Format::Strptime;
use DateTime::Format::Duration;
use List::Util qw/max/;

use overload q("") => sub { $_[0]->output };

subtype 'My::MMA' =>
    as class_type('Moose::Meta::Attribute');

our %fields;
sub add_field {
    my $self = shift;
    push @{$fields{$self}}, shift;
}

#class_has fields => (
#    traits    => ['Array'],
#    default   => sub { [] },
#    is        => 'rw',
#    isa       => 'ArrayRef[Str|My::MMA]',
#    handles  => {
#        'add_field' => 'push',
#        },
#    );

subtype 'Date' =>
    as class_type('DateTime');

coerce 'Date'
    => from 'Str'
        => via { 
            eval {
                my $f = DateTime::Format::Strptime->new( pattern => '%F' );
                my $d = $f->parse_datetime( $_ );
                $d->set_formatter($f);
                $d;
            }
            };

subtype 'Duration' =>
    as class_type('DateTime::Duration');

coerce 'Duration'
    => from 'Str'
        => via { 
            my $f = DateTime::Format::Duration->new( pattern => '%R' );
            my $d = $f->parse_duration( $_ );
            $d->{formatter} = $f;                      # direct access! Yuck!
            bless $d, 'DateTime::Duration::Formatted'; # rebless!
            return $d;
            };

sub parse {
    my ($self, $string) = @_;
    my $class = ref $self || $self;

    #my @ranges = @{ $class->fields };

    #warn "Ranges for class $class\n";
    #use Data::Dumper;
    #warn Dumper $fields{$class};
    #warn "  ".$_->name."\n" foreach @{$fields{$class}};

    #warn "Attributes for class $class\n";
    #warn "  ".$_->name."\n" foreach $class->meta->get_all_attributes;
    
    # Using class attributes seems to fail here... all of the loaded classes
    # attributes appear to be stored in the same array ref, i.e. there is no
    # separation between them.
    
    #my @ranges = $class->meta->get_all_attributes;
    my @ranges = @{$fields{$class}};
    
    my $pos = 0;
    my %data = map {
        if (ref) {
            # it's an attribute
            my $width    = $_->width;
            my $name     = $_->name;
            my $optional = $_->optional;
            my $value = substr($string, $pos, $width);
            $pos += $width;
            if ($optional && $value !~ /\S/) {
                ();
            } else {
                ($name => $value);
            }
        } else {
            # it's a string
            my $width = length;
            substr($string, $pos, $width) eq $_ or die "Invalid parse on picture '$_' ($pos)";
            $pos += $width;
            ();
        }
        } @ranges;

    #return $class->new( %data );
    return \%data;
}

sub output {
    my ($self) = @_;

    my $class  = ref $self || $self;
    my @ranges = @{$fields{$class}};
    
    my $string = join '', map {
        if (ref) {
            my $width = $_->width || 0;
            sprintf "\%${width}s", $_->get_value($self) || '';
        } else {
            $_
        }} @ranges;
    
    return $string;
}

package DateTime::Duration::Formatted;
our @ISA = 'DateTime::Duration';

use overload q("") => sub {
    my ($self) = @_;
    my $f = $self->{formatter};
    return $f->format_duration_from_deltas($f->normalise($self));
    };

1;
